import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _bash() {
  if (!Platform.isWindows) return 'bash';
  const gitBash = r'C:\Program Files\Git\bin\bash.exe';
  return File(gitBash).existsSync() ? gitBash : null;
}

void main() {
  final noBash = _bash() == null ? 'needs bash (Git Bash on Windows)' : null;

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('setup-github'));
  tearDown(() => tmp.deleteSync(recursive: true));
  String log() {
    final f = File('${tmp.path}/log');
    return f.existsSync() ? f.readAsStringSync() : '';
  }

  Future<ProcessResult> setupGithub(Map<String, String> fake) {
    final gh = File('test/tool/fakes/gh').absolute.path.replaceAll(r'\', '/');
    return Process.run(
      _bash()!,
      ['tool/infra/setup-github.sh'],
      environment: {
        'GH': gh,
        'FAKE_LOG': '${tmp.path}/log'.replaceAll(r'\', '/'),
        'FAKE_STATE': tmp.path.replaceAll(r'\', '/'),
        ...fake,
      },
    );
  }

  test('ends with its assertion lines when everything is as set', () async {
    final r = await setupGithub({});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('secret scanning: enabled'));
    expect(r.stdout, contains('push protection: enabled'));
    expect(r.stdout, contains('DEPLOY_CHANNEL=live'));
    expect(r.stdout, contains('ruleset main: as expected'));
  }, skip: noBash);

  test('fails when push protection comes back disabled', () async {
    final r = await setupGithub({'FAKE_PUSH_PROTECTION': 'disabled'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('push protection'));
  }, skip: noBash);

  test('fails when secret scanning comes back disabled', () async {
    final r = await setupGithub({'FAKE_SECRET_SCANNING': 'disabled'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('secret scanning'));
  }, skip: noBash);

  test('fails when DEPLOY_CHANNEL is not live', () async {
    final r = await setupGithub({'FAKE_DEPLOY_CHANNEL': 'next'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('DEPLOY_CHANNEL'));
  }, skip: noBash);

  test('fails when the ruleset lost a required check', () async {
    final r = await setupGithub({'FAKE_RULESET_CHECKS': 'pr-title@15368'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('ruleset'));
  }, skip: noBash);

  test('fails when a check is not bound to GitHub Actions', () async {
    final r = await setupGithub({
      'FAKE_RULESET_CHECKS':
          'gitleaks@1,pr-title@15368,verify / build@15368,workflow-lint@15368',
    });
    expect(r.exitCode, 1);
    expect(r.stderr, contains('ruleset'));
  }, skip: noBash);

  test('fails when the ruleset is not strict', () async {
    final r = await setupGithub({'FAKE_RULESET_STRICT': 'false'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('ruleset'));
  }, skip: noBash);

  test('fails when the ruleset lost a rule (linear history)', () async {
    final r = await setupGithub({
      'FAKE_RULESET_TYPES':
          'deletion,non_fast_forward,pull_request,required_status_checks',
    });
    expect(r.exitCode, 1);
    expect(r.stderr, contains('ruleset'));
  }, skip: noBash);

  test(
    'fails when the ruleset does not target exactly refs/heads/main',
    () async {
      for (final include in [
        r'~DEFAULT_BRANCH',
        'refs/heads/main,refs/heads/x',
      ]) {
        final r = await setupGithub({'FAKE_RULESET_INCLUDE': include});
        expect(r.exitCode, 1, reason: include);
        expect(r.stderr, contains('ruleset'));
      }
    },
    skip: noBash,
  );

  test('the ruleset file targets refs/heads/main', () {
    final s = File('tool/infra/github/ruleset-main.json').readAsStringSync();
    expect(s, contains('"include": ["refs/heads/main"]'));
    expect(s, isNot(contains('DEFAULT_BRANCH')));
  });

  test('fails when live has a reviewer or wait timer rule', () async {
    for (final rules in ['required_reviewers', 'wait_timer']) {
      final r = await setupGithub({'FAKE_ENV_RULES': rules});
      expect(r.exitCode, 1, reason: rules);
      expect(r.stderr, contains('protection rules'));
    }
  }, skip: noBash);

  test('fails when live allows branches besides main', () async {
    final r = await setupGithub({'FAKE_LIVE_POLICIES': r'main\nrelease'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('delete'));
    expect(r.stderr, contains('by hand'));
  }, skip: noBash);

  test('updates the existing ruleset with PUT', () async {
    final r = await setupGithub({});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      log(),
      contains('-X PUT repos/lschmidtdev/lschmidt-portfolio/rulesets/42'),
    );
    expect(
      log(),
      isNot(contains('-X POST repos/lschmidtdev/lschmidt-portfolio/rulesets')),
    );
  }, skip: noBash);

  test('creates the ruleset with POST when none exists', () async {
    final r = await setupGithub({'FAKE_NO_RULESET': '1'});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(
      log(),
      contains('-X POST repos/lschmidtdev/lschmidt-portfolio/rulesets'),
    );
    expect(r.stdout, contains('ruleset main: as expected'));
  }, skip: noBash);

  test('environment PUTs restate every protection field', () async {
    final r = await setupGithub({});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    for (final env in ['preview', 'live']) {
      expect(
        log(),
        contains(
          '-X PUT repos/lschmidtdev/lschmidt-portfolio/environments/$env',
        ),
      );
    }
    final s = File('tool/infra/setup-github.sh').readAsStringSync();
    for (final field in [
      '"wait_timer": 0',
      '"prevent_self_review": false',
      '"reviewers": []',
    ]) {
      expect(
        field.allMatches(s).length,
        greaterThanOrEqualTo(2),
        reason: field,
      );
    }
  }, skip: noBash);

  test('ignores gh warnings on stderr (stdout only)', () async {
    final r = await setupGithub({'FAKE_WARNING': 'warning: new gh available'});
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }, skip: noBash);

  test('the ruleset binds the four required checks to Actions', () {
    final s = File('tool/infra/github/ruleset-main.json').readAsStringSync();
    for (final check in [
      'pr-title',
      'workflow-lint',
      'gitleaks',
      'verify / build',
    ]) {
      expect(s, contains('"context": "$check"'));
    }
    expect('"integration_id": 15368'.allMatches(s).length, 4);
    expect(s, contains('"bypass_actors": []'));
    expect(s, contains('required_linear_history'));
    expect(s, contains('"allowed_merge_methods": ["squash"]'));
  });

  test('the script restates merge settings and keeps no secrets', () {
    final s = File('tool/infra/setup-github.sh').readAsStringSync();
    expect(s, contains('squash_merge_commit_title=PR_TITLE'));
    expect(s, contains('squash_merge_commit_message=BLANK'));
    expect(s, contains('delete_branch_on_merge=true'));
    expect(s, isNot(contains('gh secret set')));
    expect(s, isNot(contains('required_reviewers",')));
  });
}
