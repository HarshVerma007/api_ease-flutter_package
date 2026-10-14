# Contributing to api_ease

Thanks for your interest in improving api_ease. Bug reports, ideas and pull requests are all welcome.

## Reporting bugs

Open an issue and include:

- What you expected and what happened instead
- A minimal code sample that reproduces it
- Output of `flutter --version` and the package version
- Platform and device (for example "Android 14, Pixel 7")

For security problems, do **not** open a public issue. See [SECURITY.md](SECURITY.md).

## Suggesting features

Open an issue describing the problem you want to solve before writing code. This avoids wasted effort on changes that don't fit the package's goals: small, HTTP-client agnostic and dependency-light.

## Development setup

```bash
git clone <your fork>
cd api_ease
flutter pub get
flutter analyze
flutter test
```

To try changes in the example app:

```bash
cd example
flutter create .   # first time only
flutter run
```

## Pull request checklist

- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes
- [ ] New behaviour has tests
- [ ] Public APIs have `///` documentation
- [ ] `CHANGELOG.md` has an entry under an "Unreleased" heading
- [ ] README is updated if usage changed

## Code guidelines

- Follow the existing style and the rules in `analysis_options.yaml`.
- Keep `request` HTTP-client agnostic. Do not add HTTP package dependencies.
- Never use a `BuildContext` after an `await` without checking `context.mounted`.
- Keep the public API small. Export only what users need from `lib/api_ease.dart`.
- Tests must not hit the real network. Use the `@visibleForTesting` overrides on `ConnectivityChecker`.

## Commit messages

Use short, imperative messages, for example `Fix retry delay cap for linear backoff`.

## License

By contributing, you agree that your contributions are licensed under the MIT License.
