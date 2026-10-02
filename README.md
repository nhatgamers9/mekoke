# mekoke

## Phát triển

Flutter 3.47.6 (stable), Dart 3.13.5.

```
export PATH="/opt/flutter/bin:$PATH"
```

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
dart format lib test
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Khi đổi schema Drift (`lib/data/database.dart`), chạy lần lượt:

```
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/data/database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

Chạy `schema dump` trước mỗi lần tăng `schemaVersion`: file `drift_schemas/drift_schema_v<N>.json` của phiên bản cũ phải có sẵn thì mới kiểm được migration.
