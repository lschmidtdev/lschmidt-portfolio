import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

YamlMap _job(String workflow, String job) {
  final parsed =
      loadYaml(File('.github/workflows/$workflow').readAsStringSync())
          as YamlMap;
  return (parsed['jobs'] as YamlMap)[job] as YamlMap;
}

List<YamlMap> _steps(YamlMap job) =>
    (job['steps'] as YamlList).cast<YamlMap>().toList();

int _stepIndex(YamlMap job, bool Function(YamlMap step) test) =>
    _steps(job).indexWhere(test);

Iterable<File> _workflowFiles() => Directory(
  '.github/workflows',
).listSync().whereType<File>().where((f) => f.path.endsWith('.yml'));

void main() {
  test('every third-party action is pinned to a full commit SHA', () {
    final uses = RegExp(r'^\s*(?:-\s+)?uses:\s*(\S+)', multiLine: true);
    final pinned = RegExp(r'^[\w.-]+/[\w./-]+@[0-9a-f]{40}$');
    final offenders = <String>[];
    for (final file in _workflowFiles()) {
      for (final match in uses.allMatches(file.readAsStringSync())) {
        final ref = match.group(1)!;
        if (ref.startsWith('./')) continue;
        if (!pinned.hasMatch(ref)) offenders.add('${file.path}: $ref');
      }
    }
    expect(offenders, isEmpty);
  });

  test('pr-title.yml is the only workflow triggered on edited', () {
    final offenders = <String>[];
    var titleEdited = false;
    for (final file in _workflowFiles()) {
      final parsed = loadYaml(file.readAsStringSync()) as YamlMap;
      final on = parsed['on'];
      final edited =
          on is YamlMap &&
          on.values.any(
            (trigger) =>
                trigger is YamlMap &&
                (trigger['types'] as YamlList?)?.contains('edited') == true,
          );
      if (file.path.endsWith('pr-title.yml')) {
        titleEdited = edited;
      } else if (edited) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty);
    expect(titleEdited, isTrue);
  });

  test('no workflow references secrets', () {
    final secret = RegExp(r'\bsecrets\b(\.GITHUB_TOKEN\b)?');
    final offenders = <String>[];
    for (final file in _workflowFiles()) {
      for (final match in secret.allMatches(file.readAsStringSync())) {
        if (match.group(1) == null) {
          offenders.add('${file.path}: ${match.group(0)}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('no workflow installs npm packages globally', () {
    final offenders = [
      for (final file in _workflowFiles())
        if (RegExp(
          r'npm\s+(install|i)\b.*(--global|\s-g\b)',
        ).hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });

  for (final entry in {
    'pr.yml': 'preview',
    'main.yml': 'deploy-live',
  }.entries) {
    test(
      '${entry.value} installs the locked Firebase CLI before cloud login',
      () {
        final job = _job(entry.key, entry.value);
        final auth = _stepIndex(
          job,
          (s) => '${s['uses']}'.startsWith('google-github-actions/auth@'),
        );
        final node = _stepIndex(
          job,
          (s) => '${s['uses']}'.startsWith('actions/setup-node@'),
        );
        final ci = _stepIndex(job, (s) => '${s['run']}'.contains('npm ci'));
        expect(node, isNonNegative);
        expect(ci, greaterThan(node));
        expect(auth, greaterThan(ci));
        final step = _steps(job)[ci];
        expect(step['working-directory'], 'tool/e2e');
        expect(step['run'], contains('--ignore-scripts'));
        expect(
          (_steps(job)[node]['with'] as YamlMap)['node-version-file'],
          'tool/e2e/.nvmrc',
        );
        final after = _steps(
          job,
        ).skip(auth).map((s) => '${s['run']}').join('\n');
        expect(after, contains('tool/e2e/node_modules/.bin/firebase'));
        expect(
          after,
          isNot(matches(RegExp(r'(^|\s)firebase (deploy|hosting)'))),
        );
      },
    );
  }

  test('preview skips Dependabot and forks', () {
    final condition = (_job('pr.yml', 'preview')['if'] as String)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    expect(
      condition,
      "github.event.pull_request.user.login != 'dependabot[bot]' && "
      'github.event.pull_request.head.repo.full_name == github.repository',
    );
  });

  group('deploy-live', () {
    final job = _job('main.yml', 'deploy-live');
    final deploy = _steps(
      job,
    ).singleWhere((s) => '${s['run']}'.contains('firebase deploy'));
    final auth = _stepIndex(
      job,
      (s) => '${s['uses']}'.startsWith('google-github-actions/auth@'),
    );

    test('never cancels a deploy in progress', () {
      final concurrency = job['concurrency'] as YamlMap;
      expect(concurrency['group'], 'deploy-live');
      expect(concurrency['cancel-in-progress'], false);
    });

    test('deploys only next or live', () {
      final run = deploy['run'] as String;
      expect(run, contains('case "\$DEPLOY_CHANNEL" in'));
      expect(
        run,
        contains('  live) tool/e2e/node_modules/.bin/firebase deploy'),
      );
      expect(
        run,
        contains(
          '  next) tool/e2e/node_modules/.bin/firebase hosting:channel:deploy next',
        ),
      );
      expect(run, contains('  *) echo "::error::DEPLOY_CHANNEL must be'));
      expect(run, contains('exit 1 ;;'));
    });

    test('takes its inputs from variables through env, not interpolation', () {
      final env = deploy['env'] as YamlMap;
      expect(env['DEPLOY_CHANNEL'], r'${{ vars.DEPLOY_CHANNEL }}');
      expect(env['FIREBASE_PROJECT'], r'${{ vars.FIREBASE_PROJECT }}');
      expect(env['SITE_URL'], r'${{ vars.SITE_URL }}');
      expect(deploy['run'], isNot(contains(r'${{')));
    });

    test('deploy and smoke run in the same job', () {
      final run = deploy['run'] as String;
      expect(
        run,
        contains(
          r'"$RUNNER_TEMP/smoke" "$url" "$GITHUB_SHA" --expect-indexable',
        ),
      );
      expect(run.indexOf('esac'), lessThan(run.indexOf('smoke')));
    });

    test('compiles the smoke test before cloud login', () {
      final compile = _stepIndex(
        job,
        (s) => '${s['run']}'.contains('dart compile exe tool/ci/smoke.dart'),
      );
      expect(compile, isNonNegative);
      expect(auth, greaterThan(compile));
      expect(_steps(job).indexOf(deploy), greaterThan(auth));
    });

    group('stale-commit guard', () {
      final tip = _stepIndex(job, (s) => s['id'] == 'tip');

      test('is the first step, before checkout and cloud login', () {
        expect(tip, 0);
        expect(auth, greaterThan(tip));
        final step = _steps(job)[tip];
        expect(
          step['run'],
          contains(r'gh api "repos/$GITHUB_REPOSITORY/commits/main" --jq .sha'),
        );
        expect(step['run'], contains('::notice::'));
        expect((step['env'] as YamlMap)['GH_TOKEN'], r'${{ github.token }}');
      });

      test('every later step runs only while the commit is the tip', () {
        for (final step in _steps(job).skip(1)) {
          expect(
            step['if'],
            "steps.tip.outputs.current == 'true'",
            reason: '${step['name'] ?? step['uses'] ?? step['run']}',
          );
        }
      });

      test('job permissions stay minimal', () {
        final permissions = job['permissions'] as YamlMap;
        expect(permissions.keys.toSet(), {'contents', 'id-token'});
      });
    });

    test('runs in the live environment with a keyless token', () {
      expect((job['environment'] as YamlMap)['name'], 'live');
      expect((job['permissions'] as YamlMap)['id-token'], 'write');
    });
  });

  test(
    'verify runs the browser tests on the built site before uploading it',
    () {
      final job = _job('_verify.yml', 'build');
      int named(String name) => _stepIndex(job, (s) => s['name'] == name);
      final shells = named('Generate HTML shells');
      final info = named('Write build-info.json');
      final browser = named('Browser tests');
      final upload = _stepIndex(
        job,
        (s) =>
            '${s['uses']}'.startsWith('actions/upload-artifact@') &&
            (s['with'] as YamlMap)['name'] == 'web-build',
      );
      expect(shells, isNonNegative);
      expect(browser, greaterThan(shells));
      expect(browser, greaterThan(info));
      expect(upload, greaterThan(browser));
      final step = _steps(job)[browser];
      expect(step['working-directory'], 'tool/e2e');
      expect(step['run'], 'npx playwright test');
      final install = _steps(
        job,
      ).singleWhere((s) => '${s['run']}'.contains('npm ci'));
      expect(install['run'], contains('--ignore-scripts'));
    },
  );

  test('verify runs the content guard after analyze and before the build', () {
    final job = _job('_verify.yml', 'build');
    final analyze = _stepIndex(job, (s) => s['name'] == 'Analyze');
    final guard = _stepIndex(job, (s) => s['name'] == 'Content guard');
    final build = _stepIndex(job, (s) => s['name'] == 'Build web (wasm)');
    expect(guard, isNonNegative);
    expect(guard, analyze + 1);
    expect(guard, lessThan(build));
    expect(_steps(job)[guard]['run'], 'dart run tool/ci/content_guard.dart');
  });
}
