# Decision Replay

Beautiful notes app — text, checklists, photos, voice memos, color coding, labels and home widget.

## Package
- Android/iOS: `com.decisionreplaymng.decisionreplay`
- IAP prefix: `dr_pack_1` … `dr_pack_10`, `dr_remove_ads`
- Remote config: `https://api2.blwsmartware.net/N226.json`

## Build
```bash
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
```

## Google Play
See `iap_config/GOOGLE_PLAY_PRODUCTS.md` and `docs/iap_products.json`.
