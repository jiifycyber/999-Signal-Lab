# NEXUS FX Scanner Pro — Flutter Twin

This Flutter project reproduces the approved scanner concept image as a pixel-matched responsive desktop/web screen.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Build for GitHub Pages

Replace `YOUR-REPO-NAME` with your repository name:

```bash
flutter build web --release --base-href /YOUR-REPO-NAME/
```

## Main files

- `lib/main.dart` — responsive Flutter screen
- `assets/images/nexus_fx_scanner_reference.png` — approved scanner dashboard design
- `web/` — web launcher files

The current version intentionally locks the visual layer to the approved image for maximum visual fidelity. Individual scanner controls, charts, feeds, tables, filters, and buttons can be converted into live Flutter widgets without changing the layout.
