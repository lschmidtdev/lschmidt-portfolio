# lschmidt-portfolio

Source of [lschmidt.tech](https://lschmidt.tech), the portfolio website of Lucas Schmidt: a bilingual (EN/PT) Flutter Web app hosted on Firebase Hosting and deployed by GitHub Actions.

## Local commands

```sh
fvm flutter pub get
fvm flutter run -d chrome
fvm flutter test
fvm flutter build web --release --wasm
```

Install the pre-commit hook: `bash tool/hooks/install.sh`. It runs `gitleaks git --staged`, so it needs gitleaks v8.19 or newer on your PATH (without gitleaks the hook skips the scan; CI still runs it).
