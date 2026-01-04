# mobile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Add app launcher icon

Place your logo image at `mobile_app/assets/mobile_logo.png` (recommended square transparent PNG, 1024x1024).

Then, from the `mobile_app` folder run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

This will generate platform launcher icons from `assets/mobile_logo.png` for Android and iOS. The `pubspec.yaml` is configured to generate adaptive icons on Android (foreground image + background color).

Notes:
- Use a transparent PNG for the foreground so adaptive icons look correct.
- If you want a custom background image instead of a color, set `adaptive_icon_background` to the path of an image.
- For production use, keep your app icons under source control and avoid committing large unnecessary assets.
