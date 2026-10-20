import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _bash() {
  if (!Platform.isWindows) return 'bash';
  const gitBash = r'C:\Program Files\Git\bin\bash.exe';
  return File(gitBash).existsSync() ? gitBash : null;
}

const _fakeGcloud = r'''#!/usr/bin/env bash
[[ -n ${FAKE_WARNING:-} ]] && echo "$FAKE_WARNING" >&2
case "$1 $2" in
  "projects describe")
    [[ -n ${FAKE_NO_PROJECT:-} ]] && { echo "NOT_FOUND" >&2; exit 1; }
    printf '%s\n' "$3" ;;
  "iam service-accounts")
    case "$3" in
      list)
        [[ -n ${FAKE_LIST_ERROR:-} ]] && { echo "$FAKE_LIST_ERROR" >&2; exit 1; }
        printf '%s\n' "${FAKE_ACCOUNTS:-}" ;;
      keys)
        account=""
        for ((i = 1; i <= $#; i++)); do
          [[ ${!i} == --iam-account ]] && { j=$((i + 1)); account=${!j}; }
        done
        case " ${FAKE_KEYED:-} " in
          *" $account "*) printf 'keys/abc123\n' ;;
        esac ;;
      *) echo "unexpected: $*" >&2; exit 2 ;;
    esac ;;
  *) echo "unexpected: $*" >&2; exit 2 ;;
esac
''';

const _adminSdk =
    'firebase-adminsdk-vnaum@myportfolio-f0271.iam.gserviceaccount.com';
const _deployer = 'github-deployer@myportfolio-f0271.iam.gserviceaccount.com';

void main() {
  final noBash = _bash() == null ? 'needs bash (Git Bash on Windows)' : null;

  Future<ProcessResult> preflight(Map<String, String> fake) async {
    final dir = Directory.systemTemp.createTempSync('gcp-preflight');
    addTearDown(() => dir.deleteSync(recursive: true));
    final gcloud = File('${dir.path}/gcloud')..writeAsStringSync(_fakeGcloud);
    if (!Platform.isWindows) Process.runSync('chmod', ['+x', gcloud.path]);
    return Process.run(
      _bash()!,
      ['tool/infra/gcp-preflight.sh', 'myportfolio-f0271'],
      environment: {
        'GCLOUD': gcloud.path.replaceAll(r'\', '/'),
        'FAKE_ACCOUNTS': _adminSdk,
        ...fake,
      },
    );
  }

  test('passes for a personal project with no user-managed keys', () async {
    final r = await preflight({});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, contains('no user-managed service-account keys'));
  }, skip: noBash);

  test('does not require an organisation (spec section 3)', () async {
    final r = await preflight({});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stderr, isNot(contains('unexpected')));
    expect(r.stderr, isNot(contains('organisation')));
  }, skip: noBash);

  test('passes when the project has no service accounts yet', () async {
    final r = await preflight({'FAKE_ACCOUNTS': ''});
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }, skip: noBash);

  test('fails naming the account that has a key', () async {
    final r = await preflight({
      'FAKE_ACCOUNTS': '$_adminSdk\n$_deployer',
      'FAKE_KEYED': _deployer,
    });
    expect(r.exitCode, 1);
    expect(r.stderr, contains(_deployer));
    expect(r.stderr, contains('user-managed key'));
    expect(r.stderr, isNot(contains(_adminSdk)));
  }, skip: noBash);

  test('names every account that has a key', () async {
    final r = await preflight({
      'FAKE_ACCOUNTS': '$_adminSdk\n$_deployer',
      'FAKE_KEYED': '$_adminSdk $_deployer',
    });
    expect(r.exitCode, 1);
    expect(r.stderr, contains(_adminSdk));
    expect(r.stderr, contains(_deployer));
  }, skip: noBash);

  test('fails when the project does not exist', () async {
    final r = await preflight({'FAKE_NO_PROJECT': '1'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('myportfolio-f0271'));
    expect(r.stderr, contains('not found'));
  }, skip: noBash);

  test('fails clearly when accounts cannot be listed', () async {
    final r = await preflight({'FAKE_LIST_ERROR': 'SERVICE_DISABLED'});
    expect(r.exitCode, 1);
    expect(r.stderr, contains('cannot list the service accounts'));
    expect(r.stderr, contains('SERVICE_DISABLED'));
  }, skip: noBash);

  test('ignores gcloud warnings on stderr (stdout only)', () async {
    final r = await preflight({'FAKE_WARNING': 'WARNING: Updates available'});
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, isNot(contains('WARNING')));
  }, skip: noBash);

  test('setup-gcp.sh runs the pre-flight before any change', () {
    final lines = File('tool/infra/setup-gcp.sh').readAsLinesSync();
    final check = lines.indexWhere(
      (l) => l.contains(r'gcp-preflight.sh" "$PROJECT"'),
    );
    final enable = lines.indexWhere(
      (l) => l.contains('gcloud services enable'),
    );
    expect(check, isNot(-1));
    expect(enable, isNot(-1));
    expect(check, lessThan(enable));
  });

  test('setup-gcp.sh binds one deployer to this repo, with one role', () {
    final s = File('tool/infra/setup-gcp.sh').readAsStringSync();
    expect(s, contains('lschmidtdev/lschmidt-portfolio'));
    expect(s, contains('PROVIDER=lschmidt-portfolio'));
    expect(s, contains('roles/firebasehosting.admin'));
    expect(s, contains('assertion.repository_owner_id =='));
    expect(s, contains('attribute.repository/'));
    expect(s, isNot(contains('firebase-adminsdk')));
    expect(s, isNot(contains('service-accounts keys create')));
  });
}
