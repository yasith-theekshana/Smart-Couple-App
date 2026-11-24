# SmartCouple

SmartCouple is an Android app for couples to manage household responsibilities together. Step 01 provides the Flutter application shell with English and French localization.

## Local development

Use Flutter 3.47.1 with Dart 3.13.1 and an Android SDK configured for Flutter.

```sh
flutter pub get
flutter gen-l10n
flutter run
```

Edit the ARB files in `lib/l10n/` to update translations. Flutter generates the Dart localization files during a build, or you can regenerate them with `flutter gen-l10n`.

Application composition, routing, and themes live in `lib/app/`. Shared code lives in `lib/core/`, and screens and feature logic live in `lib/features/`. Add application, domain, and data layers as each feature needs them.
