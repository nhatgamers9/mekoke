# Kế hoạch: Steady, giai đoạn 1 (nền móng + tab Streaks + tab Check-in)

Yêu cầu gốc: "giờ giúp tôi hoàn thiện phần mềm để nó hoạt động tránh mọi lỗi vặt". Repo hiện chưa có dòng code nào.
Kế hoạch này đề xuất **chia giai đoạn**. Giai đoạn 1 (GĐ1) phải chạy được và kiểm thử được trọn vẹn trên máy này.

---

## CÂU HỎI CÒN BỎ NGỎ

Coder: chừng nào mục này còn trong file thì DỪNG. Người dùng trả lời "đồng ý" nghĩa là nhận mọi đề xuất mặc định bên dưới. Khi đã có câu trả lời, agent điều phối sửa các mục liên quan (nếu người dùng chọn khác mặc định) rồi xoá mục này, sau đó mới giao cho Coder.

| # | Câu hỏi | Đề xuất mặc định |
|---|---|---|
| Q1 | "Hoàn thiện phần mềm" là cả app: 5 tab, onboarding, paywall, quảng cáo, đăng nhập, widget. Làm hết trong một lần thì quá lớn, và nhiều phần còn thiếu dữ kiện. Chia giai đoạn có được không? | Có chia. GĐ1 gồm đúng mục 1. Các giai đoạn sau: GĐ2 Timer (nhịn ăn + HIIT, thông báo), GĐ3 Money, GĐ4 Focus (âm thanh), GĐ5 Settings/onboarding/paywall/quảng cáo/widget. Nếu muốn ưu tiên khác (ví dụ Money trước) thì nói. |
| Q2 | Có cài Flutter SDK vào môi trường này không? GĐ1 chỉ kiểm chứng bằng `flutter analyze` và `flutter test` trên Linux. Máy không có Android SDK nên **không build được APK và không chạy được trên điện thoại**. | Cài Flutter stable vào `/opt/flutter` (nằm ngoài repo). GĐ1 không build APK. Nếu bạn cần APK để cài thử ngay thì phải thêm bước cài Android SDK + JDK, và bước này chưa xác minh là tải được. |
| Q3 | applicationId trên CH Play. Có thể đổi trước lần tải lên đầu tiên, nhưng sau đó thì **vĩnh viễn không đổi được**. | `com.mekoke.steady` |
| Q4 | Chọn cơ sở dữ liệu: Isar hay Drift? | Drift (SQLite). Isar bản gốc đã ngừng bảo trì, còn Drift chạy test in-memory được trên Linux. |
| Q5 | Đếm ngày "sạch" thế nào? A: ngày bắt đầu là 0 days, qua mỗi nửa đêm +1 (khớp số trong mockup: Since May 28 thì ngày Oct 2 là 127). B: ngày bắt đầu đã là 1 day (khớp câu "Day 1 starts now"). | A. Chip trên Check-in hiện "Day {n}" với n là số ngày theo A, nên có thể ra "Day 0". |
| Q6 | Chuỗi nào là chuỗi chính (thẻ lớn)? Các chuỗi còn lại xếp ra sao? | Chuỗi chính là chuỗi nhiều ngày nhất (ngày bắt đầu sớm nhất); bằng nhau thì chuỗi tạo trước đứng trước. Các chuỗi khác xếp giảm dần theo số ngày. Chip trên Check-in hiện chuỗi chính. |
| Q7 | Qua mốc 365 ngày thì thanh mốc hiện gì? | Ẩn thanh mốc, vì không còn mốc kế tiếp. |
| Q8 | Luồng thêm / đặt lại / xoá thói quen chưa có bản vẽ. | Làm như mục 6.3: sheet "Add habit" (tên 1–40 ký tự, ngày "Clean since" mặc định hôm nay, không cho chọn ngày tương lai). Chạm vào thẻ thì mở sheet có "Reset streak" và "Delete habit". Xoá phải qua hộp xác nhận; đặt lại thì không cần xác nhận thêm. Tên trùng nhau vẫn cho phép. |
| Q9 | Quy tắc Check-in? | Mỗi ngày một bản; lưu lại trong cùng ngày thì ghi đè. Ngày tính từ 00:00 theo giờ máy. Lời chào theo giờ: 05:00–11:59 morning, 12:00–17:59 afternoon, còn lại evening. Ghi chú chỉ một dòng (xuống dòng bị đổi thành dấu cách). GĐ1 chưa có màn lịch sử. |
| Q10 | Một số câu chữ chưa có trong thiết kế (dòng đánh dấu MỚI ở mục 7). | Dùng đúng như bảng ở mục 7. |
| Q11 | Màn Settings chưa có. | GĐ1 ẩn nút Settings để không có nút bấm không làm gì. App luôn dùng theme Dark. |
| Q12 | Có khoá xoay màn hình không? | Khoá dọc (portrait). |
| Q13 | Android tự sao lưu dữ liệu app lên Google Drive, trái với lời hứa "dữ liệu chỉ ở trên máy". | Tắt (`android:allowBackup="false"`) cho tới khi chốt tính năng sao lưu. Hệ quả: đổi máy là mất dữ liệu. |

Những việc để sau, không chặn GĐ1: backend đăng nhập/sao lưu, file âm mưa CC0, ID AdMob/Play Billing, icon app, bản dịch es/de/fr/ja.

---

## 1. Phạm vi GĐ1

**Làm:**
- Dựng project Flutter ở gốc repo.
- Chép design system vào repo.
- Theme Dark từ tokens, font, icon, l10n (chỉ tiếng Anh).
- DB Drift, khung 5 tab.
- **Streaks**: thêm, xem, đặt lại, xoá thói quen; tính mốc.
- **Check-in**: chọn tâm trạng + ghi chú, lưu theo ngày.
- Focus, Timer, Money: chỉ có màn chờ (placeholder).
- Chỉnh Android tối thiểu: tên app, nền khi khởi động, sao lưu.

**Không làm:** âm thanh, hẹn giờ, thông báo, Money, onboarding, paywall, quảng cáo, đăng nhập, widget màn hình chính, Settings, theme Light/Bedtime trên UI (chỉ khai báo hằng màu), lịch sử Check-in, đổi tên thói quen, build APK. Không thêm package nào ngoài mục 4.

---

## 2. Môi trường và lệnh

Đặt `SRC=/tmp/claude-0/-home-user-mekoke/cc7bfc32-2202-5695-aafd-72552f98ca86/scratchpad` (bản sao tạm của session).

1. **Cài Flutter**
   - Tải `https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`, lấy `current_release.stable` (hash), tìm phần tử `releases[]` có cùng `hash`, lấy trường `archive`.
   - Tải `https://storage.googleapis.com/flutter_infra_release/releases/<archive>` rồi `tar -xJf <file> -C /opt`.
   - Chạy lần lượt: `git config --global --add safe.directory /opt/flutter`, `export PATH="/opt/flutter/bin:$PATH"`, `flutter config --no-analytics`, `flutter --version`.
   - Không commit SDK, không cài Android SDK.
2. **Tạo project**
   - Sao lưu `README.md`, rồi chạy tại `/home/user/mekoke`: `flutter create --project-name steady --org com.mekoke --platforms android --empty .`
   - Khôi phục `README.md` gốc (dòng `# mekoke`) và thêm mục "Phát triển" (bước 5). Nếu có `test/widget_test.dart` thì xoá.
3. **Lệnh kiểm chứng**, chạy theo đúng thứ tự:
   ```
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter gen-l10n
   dart format lib test
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   ```
   Nếu test báo `Failed to load dynamic library 'libsqlite3.so'` thì chạy `apt-get install -y libsqlite3-dev` và ghi việc này vào README.
4. Nếu có lệnh `graphify` thì chạy `graphify update .` sau khi xong code (theo CLAUDE.md).
5. Mục "Phát triển" trong README chỉ gồm: phiên bản Flutter/Dart đã cài, dòng `export PATH`, và các lệnh ở bước 3.

---

## 3. Danh sách file

Mọi đường dẫn tính từ `/home/user/mekoke/`. File do `flutter create` sinh ra thì chỉ sửa đúng chỗ được nêu.

| File | Việc |
|---|---|
| `pubspec.yaml` | sửa: deps (mục 4); `flutter: generate: true`, `uses-material-design: true`; assets `assets/icons/`, `assets/fonts/OFL-Newsreader.txt`, `assets/fonts/OFL-Figtree.txt`; fonts `Newsreader` → `assets/fonts/Newsreader-Variable.ttf`, `Figtree` → `assets/fonts/Figtree-Variable.ttf` |
| `l10n.yaml` | mới: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `output-class: AppLocalizations`, `nullable-getter: false`. Nếu Flutter cảnh báo về `synthetic-package` thì làm theo hướng dẫn trong cảnh báo; file sinh ra phải nằm ở `lib/l10n/` |
| `README.md` | thêm mục "Phát triển" |
| `android/app/src/main/AndroidManifest.xml` | `android:label="Steady"`, `android:allowBackup="false"` (Q13). Không thêm permission nào |
| `android/app/src/main/res/values/colors.xml` | mới: `<color name="launch_bg">#121110</color>` |
| `android/app/src/main/res/drawable/launch_background.xml`, `drawable-v21/launch_background.xml` | item nền dùng `@color/launch_bg` thay cho màu trắng |
| `android/app/src/main/res/values/styles.xml`, `values-night/styles.xml` | `NormalTheme` có `android:windowBackground` = `@color/launch_bg` |
| `design/steady-ds/README.md`, `design/steady-ds/tokens.json` | chép từ `$SRC/steady-ds/project/` |
| `design/steady-ds/components/` | chép từ `$SRC/steady-ds/project/components/`: mọi `*/README.md`, `bundle.js`, `bundle.css`. Bỏ `preview.html` |
| `design/mockups/steady/*.dc.html` | chép từ `$SRC/steady-canvas/project/*.dc.html` |
| `design/mockups/money/*.dc.html` | chép từ `$SRC/money-canvas/project/*.dc.html` |
| `assets/icons/*.svg` | chép cả 67 file từ `$SRC/steady-ds/project/assets/Icons/`, giữ nguyên tên |
| `assets/icons/LICENSE` | chép từ `$SRC/ds-src/lucide/package/LICENSE` (ISC) |
| `assets/fonts/*` | mục 5.2 |
| `lib/main.dart` | thay toàn bộ (mục 5.9) |
| `lib/app.dart` | `SteadyApp` |
| `lib/core/services.dart` | `AppServices`, `ServicesScope` |
| `lib/core/time/local_date.dart` | `LocalDate` |
| `lib/core/time/today_notifier.dart` | `TodayNotifier` |
| `lib/core/format/formatting.dart` | định dạng theo locale |
| `lib/core/theme/tokens.dart` | `SteadyColors`, `SteadySpace`, `SteadyRadius`, `SteadySize` |
| `lib/core/theme/typography.dart` | `SteadyText` |
| `lib/core/theme/app_theme.dart` | `buildSteadyTheme` |
| `lib/data/database.dart` (+ `database.g.dart` sinh ra, có commit) | Drift |
| `lib/data/habit_repository.dart`, `lib/data/check_in_repository.dart` | repository |
| `lib/l10n/app_en.arb` (+ file sinh ra) | copy ở mục 7 |
| `lib/features/shell/home_shell.dart` | khung 5 tab |
| `lib/features/placeholder/placeholder_screen.dart` | màn chờ |
| `lib/features/streaks/streak_math.dart`, `habit_name.dart`, `streaks_screen.dart`, `add_habit_sheet.dart`, `habit_actions_sheet.dart` | Streaks |
| `lib/features/check_in/check_in_rules.dart`, `check_in_screen.dart` | Check-in |
| `lib/ui/components/steady_icon.dart`, `steady_button.dart`, `steady_chip.dart`, `steady_progress_bar.dart`, `streak_card.dart`, `mood_picker.dart`, `steady_tab_bar.dart`, `steady_text_field.dart`, `steady_dialogs.dart` | component |
| `test/helpers/test_app.dart`, `test/app_smoke_test.dart` | Coder viết (mục 9) |

---

## 4. Phụ thuộc

Thêm bằng lệnh, không tự gõ số phiên bản:

1. `flutter pub add flutter_localizations --sdk=flutter`
2. `flutter pub add drift drift_flutter flutter_svg clock characters intl:any`. Để `intl` ở `any` để nó theo đúng bản mà `flutter_localizations` ghim; đây là lỗi xung đột phiên bản rất hay gặp.
3. `flutter pub add --dev drift_dev build_runner`

Giữ `flutter_lints` do template sinh. **Cấm** thêm riverpod, provider, get_it, google_fonts hay bất kỳ package nào khác.

---

## 5. Nền móng

### 5.1 Quy tắc chung
- Thời gian chỉ lấy qua `services.clock.now()` (`package:clock`). Trong `lib/` không được có `DateTime.now()`.
- Màu chỉ lấy từ `SteadyColors.of(context)`. `Color(0x…)` chỉ được xuất hiện trong `tokens.dart`.
- Khoảng cách, bo góc, kích thước lấy từ `SteadySpace`, `SteadyRadius`, `SteadySize`. Kiểu chữ lấy từ `SteadyText`.
- Mọi chữ hiển thị đi qua `AppLocalizations`.
- Dùng API không deprecated của bản Flutter đã cài (ví dụ `Color.withValues(alpha:)`).
- Sau mỗi `await` trong widget phải kiểm `context.mounted`. Lấy `ScaffoldMessenger.of(context)` và `Navigator` **trước** khi `await` hoặc `pop`.

### 5.2 Font
Tải từ `https://raw.githubusercontent.com/google/fonts/main/`:
- `ofl/newsreader/Newsreader%5Bopsz%2Cwght%5D.ttf` → `assets/fonts/Newsreader-Variable.ttf`
- `ofl/figtree/Figtree%5Bwght%5D.ttf` → `assets/fonts/Figtree-Variable.ttf`
- `ofl/newsreader/OFL.txt` → `assets/fonts/OFL-Newsreader.txt`
- `ofl/figtree/OFL.txt` → `assets/fonts/OFL-Figtree.txt`

Gặp 404 thì xem đúng tên file qua `https://api.github.com/repos/google/fonts/contents/ofl/<tên>`. Không dùng file Italic, không dùng `.woff2` của bản preview.

### 5.3 `tokens.dart`
Chép đúng giá trị từ `design/steady-ds/tokens.json`, không tự đặt token mới.
- `@immutable class SteadyColors extends ThemeExtension<SteadyColors>`
  - Field theo camelCase của tên token: `bg, surface, surface2, line, lineStrong, ink, inkMuted, amber, onAmber, amberSoft, tide, onTide, tideSoft, rose, onRose, roseSoft`.
  - Thêm `sheetShadow` lấy màu từ `shadow-sheet`: dark `0xB3000000`, light `0x241C1916`, bedtime `0xFF000000`. Lưu ý CSS `#RRGGBBAA` chuyển sang Flutter là `0xAARRGGBB`.
  - Có `static const dark`, `light`, `bedtime`; `copyWith`; `lerp` (dùng `Color.lerp` cho từng field); `static SteadyColors of(BuildContext)`.
- `abstract final class SteadySpace { s1=4, s2=8, s3=12, s4=16, s5=20, s6=24, s8=32, s12=48 }`
- `SteadyRadius { sm=8, md=14, lg=22, xl=30, full=9999 }`
- `SteadySize { tap=48, button=52, buttonMd=44, play=72, ring=264, ringStroke=14, tabbar=72 }`. Riêng `buttonMd` lấy từ `bundle.css` `.st-btn-md`.

### 5.4 `typography.dart`
`abstract final class SteadyText` có các `static const TextStyle` **không mang màu**: `countXl, timerXl, display, title` (Newsreader); `headline, body, bodyStrong, label, caption, overline, moneyXl, countGym, stat` (Figtree).
- `fontSize` lấy từ tokens; `height = lineHeight / fontSize`; `letterSpacing = em × fontSize`.
- Đặt **cả** `fontWeight: FontWeight.wN` **lẫn** `fontVariations: [FontVariation('wght', N)]`, vì font variable không tự nhận `fontWeight`.
- `countGym` và `stat` có `fontFeatures: [FontFeature.tabularFigures()]`.

### 5.5 `app_theme.dart`
`ThemeData buildSteadyTheme(SteadyColors c, Brightness b)`:
- `useMaterial3: true`, `fontFamily: 'Figtree'`, `scaffoldBackgroundColor: c.bg`, `extensions: [c]`.
- `ColorScheme`:
  - primary amber / onPrimary onAmber; secondary tide / onSecondary onTide; error rose / onError onRose.
  - surface surface / onSurface ink; onSurfaceVariant inkMuted; outline lineStrong; outlineVariant line.
  - primaryContainer amberSoft / onPrimaryContainer amber; secondaryContainer tideSoft / onSecondaryContainer tide; errorContainer roseSoft / onErrorContainer rose.
  - surfaceContainerLowest, Low và surfaceContainer = surface; surfaceContainerHigh và Highest = surface2.
  - **`surfaceTint: Colors.transparent`** để sheet và dialog không bị ám màu amber.
- splashColor và highlightColor = ink ở alpha 0.08.
- textSelectionTheme: con trỏ amber, vùng chọn amber alpha 0.4, tay nắm amber.
- bottomSheetTheme: nền trong suốt, elevation 0.
- dialogTheme: nền surface, bo `radius-lg`.
- snackBarTheme: nền surface2, chữ `body` màu ink, `behavior: floating`.
- GĐ1 chỉ dùng `buildSteadyTheme(SteadyColors.dark, Brightness.dark)`.

### 5.6 Icon (`steady_icon.dart`)
- `abstract final class SteadyIcons { audioWaveform='audio-waveform', timer='timer', sprout='sprout', wallet='wallet', notebookPen='notebook-pen', plus='plus' }`. Chỉ khai báo những tên GĐ1 dùng.
- `SteadyIcon(String name, {double size = 24, Color? color, String? semanticLabel})` render bằng `SvgPicture.asset('assets/icons/$name.svg')` với `colorFilter: ColorFilter.mode(color ?? ink, BlendMode.srcIn)`. Nếu `semanticLabel == null` thì `excludeFromSemantics: true`.

### 5.7 Định dạng (`formatting.dart`)
- `String formatLocaleTag(Locale appLocale, Locale deviceLocale)`: nếu hai locale cùng `languageCode` và `DateFormat.localeExists(tag của máy)` thì trả tag của máy (ví dụ `en_GB`); ngược lại trả `appLocale.languageCode`.
- `String formatLocaleOf(BuildContext c)` dùng `Localizations.localeOf(c)` và `View.of(c).platformDispatcher.locale`.
- `String formatShortDate(LocalDate d, LocalDate today, String tag)`: cùng năm với `today` thì dùng `DateFormat.MMMd` ("May 28"), khác năm thì `DateFormat.yMMMd` ("May 28, 2025").
- `String formatLongDate(LocalDate d, String tag)` dùng `DateFormat.MMMMEEEEd` ("Friday, October 2").
- `main()` và test phải gọi `await initializeDateFormatting()` (`package:intl/date_symbol_data_local.dart`).

### 5.8 Thời gian
```dart
// local_date.dart
@immutable
class LocalDate implements Comparable<LocalDate> {
  LocalDate(int year, int month, int day); // ArgumentError nếu ngày không có thật (so khứ hồi với DateTime.utc)
  factory LocalDate.fromDateTime(DateTime dt); // dt.isUtc thì đổi toLocal() trước
  factory LocalDate.parse(String iso);         // đúng dạng 'YYYY-MM-DD', còn lại FormatException
  final int year, month, day;
  int get epochDay;                 // DateTime.utc(y,m,d).millisecondsSinceEpoch ~/ 86400000
  int daysUntil(LocalDate other);   // other.epochDay - epochDay
  LocalDate addDays(int days);
  DateTime toDateTime();            // DateTime(y,m,d), giờ máy
  String toIso();                   // 'YYYY-MM-DD', đệm số 0
  bool isBefore(LocalDate o); bool isAfter(LocalDate o);
  // compareTo, ==, hashCode, toString
}

// today_notifier.dart
class TodayNotifier extends ValueNotifier<LocalDate> with WidgetsBindingObserver {
  TodayNotifier(Clock clock);
  void refresh(); // value = LocalDate.fromDateTime(clock.now())
  void start();   // addObserver + Timer tới DateTime(y, m, d + 1) + 1 giây; khi chạy thì refresh() rồi hẹn lại
  void stop();    // removeObserver + huỷ Timer; gọi nhiều lần không lỗi
  // didChangeAppLifecycleState: khi resumed thì refresh() và hẹn lại Timer. dispose() gọi stop().
}
```

### 5.9 DB, repository, services, khởi động
```dart
// database.dart
class LocalDateConverter extends TypeConverter<LocalDate, String> { const LocalDateConverter(); } // toIso / parse
@DataClassName('Habit')
class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // KHÔNG dùng withLength: Drift đếm theo UTF-16, sai với emoji
  TextColumn get cleanSince => text().map(const LocalDateConverter())();
  DateTimeColumn get createdAt => dateTime()();
}
@DataClassName('CheckIn')
class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().map(const LocalDateConverter()).unique()();
  IntColumn get mood => integer().check(mood.isBetweenValues(1, 5))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}
@DriftDatabase(tables: [Habits, CheckIns])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  static AppDatabase openDefault(); // AppDatabase(driftDatabase(name: 'steady'))
  @override int get schemaVersion => 1; // migration: onCreate => m.createAll()
}

// habit_repository.dart
class HabitRepository {
  HabitRepository(AppDatabase db, Clock clock);
  Stream<List<Habit>> watchHabits(); // ORDER BY cleanSince ASC, createdAt ASC, id ASC
  Future<Habit> addHabit({required String name, required LocalDate cleanSince, required LocalDate today});
  // ArgumentError nếu normalizeHabitName(name) == null hoặc cleanSince.isAfter(today). Lưu tên đã chuẩn hoá.
  Future<bool> resetStreak(int id, LocalDate today); // cleanSince = today; id không tồn tại thì trả false
  Future<bool> deleteHabit(int id);                  // id không tồn tại thì trả false
}

// check_in_repository.dart
class CheckInRepository {
  CheckInRepository(AppDatabase db, Clock clock);
  Future<CheckIn?> getForDate(LocalDate date);
  Future<void> saveForDate({required LocalDate date, required Mood mood, String? note});
  // note đi qua normalizeCheckInNote (ArgumentError nếu quá dài).
  // Upsert theo `date`: insert(..., onConflict: DoUpdate(..., target: [checkIns.date])).
}

// services.dart
class AppServices {
  AppServices({required AppDatabase db, required Clock clock}); // tự tạo habits, checkIns, today
  final AppDatabase db; final Clock clock;
  final HabitRepository habits; final CheckInRepository checkIns; final TodayNotifier today;
  Future<void> dispose(); // today.dispose(); await db.close();
}
class ServicesScope extends InheritedWidget {
  const ServicesScope({required this.services, required super.child});
  static AppServices of(BuildContext context);
}
```
- `lib/main.dart` làm theo thứ tự: `WidgetsFlutterBinding.ensureInitialized()`, `SystemChrome.setPreferredOrientations([portraitUp])`, `await initializeDateFormatting()`, rồi `runApp(SteadyApp(services: AppServices(db: AppDatabase.openDefault(), clock: const Clock())))`.
- `lib/app.dart`: `SteadyApp({required AppServices services})` bọc `ServicesScope` quanh `MaterialApp`:
  - `title: 'Steady'`, `debugShowCheckedModeBanner: false`, theme Dark.
  - `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`.
  - `home: const HomeShell()`.

---

## 6. Màn hình và component

Hình dáng component bám theo `design/steady-ds/components/<Tên>/README.md` cộng với class `.st-*` trong `design/steady-ds/components/bundle.css`. Bố cục màn hình bám theo `design/mockups/steady/Streaks.dc.html` và `CheckIn.dc.html`. **Riêng TabBar trong mockup đang có 4 tab là bản cũ; làm theo `components/TabBar/README.md` với 5 tab.**

### 6.1 Component (`lib/ui/components/`)
- **`SteadyButton`**
  - Chữ ký: `({required String label, required VoidCallback? onPressed, SteadyButtonVariant variant = .secondary, SteadyButtonSize size = .lg, bool block = false, String? icon})`.
  - Dựng trên `FilledButton` với `StadiumBorder`, elevation 0, `tapTargetSize: MaterialTapTargetSize.padded` (nút md cao 44 vẫn có vùng chạm 48).
  - `minimumSize` cao 52 (lg) hoặc 44 (md); padding ngang 24 (lg) hoặc 20 (md). Chữ `bodyStrong`; icon 20; khoảng cách 8. Nhãn để trong `Flexible`, `maxLines: 1`, ellipsis.
  - Màu: primary nền amber / chữ onAmber; secondary surface2 / ink; ghost trong suốt / amber; danger roseSoft / rose.
  - `onPressed == null` thì bọc `Opacity(0.4)` và giữ nguyên màu (đặt `disabled*Color` bằng màu thường).
- **`SteadyChip`**: `({required String label, SteadyChipTone tone = .neutral, String? icon})`. Cao **tối thiểu** 28 (không cố định), padding ngang 12 và dọc 4, bo full; icon 16, khoảng cách 4, chữ `label`. Tone: neutral surface2/inkMuted, amber amberSoft/amber, tide tideSoft/tide, rose roseSoft/rose. Nhãn ellipsis.
- **`SteadyProgressBar`**: `({required double value, required String semanticLabel, SteadyBarTone tone = .amber})`. Kẹp value vào 0..1. Cao 8, bo `sm`, rãnh surface2, phần đã chạy tide hoặc amber. Semantics có `label` và `value: '${(v*100).round()}%'`.
- **`StreakCard`**
  - Chữ ký: `({required String habit, required int days, required String since, StreakCardSize size = .lg, StreakMilestoneView? milestone, VoidCallback? onTap})`, với `class StreakMilestoneView { final String label; final double progress; }`.
  - Thẻ: padding 20, bo `lg`, nền surface, khoảng cách 8.
  - Dòng đầu là `Wrap(alignment: spaceBetween)` gồm tên (`headline`, ink) và since (`label`, inkMuted).
  - Dòng số gồm số (`countXl` nếu lg, `stat` nếu sm) và đơn vị (`body`, inkMuted, chọn số ít/số nhiều qua l10n), bọc `FittedBox(fit: scaleDown, alignment: centerLeft)`. Với lg thì thêm margin dọc 8.
  - Phần mốc gồm `SteadyProgressBar` tide và caption inkMuted.
  - Toàn thẻ là một `InkWell` (bo `lg`) với `MergeSemantics` + `Semantics(button: onTap != null)`.
- **`MoodPicker`**
  - Chữ ký: `({required Mood? value, required ValueChanged<Mood> onChanged})`.
  - Lưới 5 cột bằng nhau, khoảng cách 8. Mỗi ô: padding dọc 12, bo `md`, viền 2 (trong suốt; ô đang chọn thì amber), nền surface2 (đang chọn thì amberSoft), màu inkMuted (đang chọn thì amber).
  - Nội dung ô: mặt cười 32 + khoảng 4 + nhãn `caption` bọc `FittedBox(scaleDown)`, `maxLines: 1`.
  - Mỗi ô là `Semantics(button: true, selected: on, inMutuallyExclusiveGroup: true, label: tên mức)`.
  - Mặt cười là `SvgPicture.string` dùng mẫu sau (đổi `{D}` theo mức 1..5) và tô màu bằng `colorFilter`:
    `<svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.75" stroke-linecap="round"><circle cx="12" cy="12" r="9.5"/><circle cx="9" cy="10" r="0.6" fill="#000"/><circle cx="15" cy="10" r="0.6" fill="#000"/><path d="{D}"/></svg>`
  - Giá trị `{D}`: 1 `M8 16.5q4-4 8 0` · 2 `M8.5 16q3.5-2 7 0` · 3 `M8.5 15.5h7` · 4 `M8.5 14.5q3.5 2.5 7 0` · 5 `M7.5 14q4.5 4.5 9 0`.
- **`SteadyTabBar`**
  - Chữ ký: `({required List<SteadyTabItem> items, required int current, required ValueChanged<int> onChanged})`, với `SteadyTabItem(icon, label)`.
  - Cao 72 cộng phần đệm an toàn phía dưới. Nền surface, viền trên 1px màu line. Các cột chia đều.
  - Viên nền icon 56×30 bo full; icon 22; khoảng cách 4; nhãn `caption`, `maxLines: 1`, ellipsis.
  - Tab đang mở: viên amberSoft, icon amber, chữ ink. Tab khác: inkMuted.
  - Bọc `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`. Semantics mỗi tab: `button`, `selected`, `label`.
- **`SteadyTextField`**: `({required TextEditingController controller, String? hint, int? maxLength, int minLines = 1, int maxLines = 1, List<TextInputFormatter>? inputFormatters, TextInputAction? textInputAction, bool autofocus = false, ValueChanged<String>? onChanged})`. Nền surface, viền 2px lineStrong (khi focus là amber), bo `md`, padding 12/16. Chữ `body` ink, hint inkMuted. `counterText: ''` (ẩn bộ đếm mặc định), `MaxLengthEnforcement.enforced`, `onTapOutside` thì unfocus.
- **`steady_dialogs.dart`**
  - `Future<T?> showSteadySheet<T>(BuildContext, {required WidgetBuilder builder})`: dùng `showModalBottomSheet` với `isScrollControlled: true`, `useSafeArea: true`, nền trong suốt. Nội dung là Container nền surface, bo trên `xl`, `BoxShadow(offset: (0,-12), blurRadius: 40, color: sheetShadow)`, padding 24 trên, 20 hai bên, dưới 20 cộng `viewInsets.bottom`. Bên trong là `SingleChildScrollView` + `Column(mainAxisSize: min)`.
  - `Future<bool> showSteadyConfirmDialog(BuildContext, {required String title, required String body, required String confirmLabel, required String cancelLabel})`: tiêu đề `title`, thân `body` inkMuted. Hai nút md: ghost (huỷ) và danger (xác nhận). Chỉ trả `true` khi bấm xác nhận; chạm ra ngoài thì `false`.
  - `void showSteadySnackBar(ScaffoldMessengerState m, String message)`: ẩn snackbar đang hiện rồi mới hiện cái mới.

### 6.2 Shell (`home_shell.dart`) và placeholder
- `HomeShell` (StatefulWidget). `initState` gọi `services.today.start()`, `dispose` gọi `stop()`.
- Thứ tự tab cố định: 0 Focus (`audio-waveform`), 1 Timer (`timer`), 2 Streaks (`sprout`), 3 Money (`wallet`), 4 Check-in (`notebook-pen`). Mở app vào tab 0.
- `Scaffold(body: SafeArea(bottom: false, child: IndexedStack(...)), bottomNavigationBar: SteadyTabBar)`. `IndexedStack` giữ trạng thái của từng tab.
- `PopScope(canPop: index == 0)`: khi bị chặn (`didPop == false`) thì chuyển về tab 0. Sheet và dialog tự đóng trước theo mặc định.
- `AnnotatedRegion<SystemUiOverlayStyle>`: status bar trong suốt, icon sáng; navigation bar màu surface, icon sáng.
- `PlaceholderScreen({required String title})`: padding trên 32, hai bên 20. Tiêu đề `display` ink, cách 16, rồi `placeholderBody` (`body`, inkMuted).

### 6.3 Streaks
- **`streak_math.dart`**
  - `const kStreakMilestones = [1, 3, 7, 14, 30, 60, 90, 180, 365];`
  - `int daysClean(LocalDate cleanSince, LocalDate today)` = `max(0, cleanSince.daysUntil(today))` (phương án A ở Q5).
  - `class MilestoneProgress { final int next; final int remaining; final double progress; }`
  - `MilestoneProgress? nextMilestone(int days)`:
    - `next` = mốc nhỏ nhất lớn hơn `days`; không có thì trả `null` (từ 365 trở lên).
    - `prev` = mốc lớn nhất nhỏ hơn hoặc bằng `days`, không có thì 0.
    - `progress = (days - prev) / (next - prev)`; `remaining = next - days`.
- **`habit_name.dart`**: `const kHabitNameMaxChars = 40;` và `String? normalizeHabitName(String raw)`: trim; trả `null` nếu rỗng, chứa `\r` hoặc `\n`, hoặc dài quá 40 **grapheme** (`raw.characters.length`).
- **`StreaksScreen`**
  - Lắng nghe `StreamBuilder(habits.watchHabits())` và `ValueListenableBuilder(today)`.
  - Toàn bộ là `ListView` (padding 32 trên, 20 hai bên và dưới, khoảng cách 16), gồm lần lượt:
    1. Tiêu đề `display` "Streaks".
    2. Thói quen đầu tiên: `StreakCard` lg, có mốc nếu `nextMilestone` khác null. Nhãn mốc dùng `milestoneNext`.
    3. Các thói quen còn lại: `StreakCard` sm, không có mốc.
    4. `SteadyButton` secondary, block, icon `plus`, nhãn "Add habit".
  - Since hiển thị bằng `streakSince(formatShortDate(...))`.
  - Chưa có thói quen nào: tiêu đề + `streaksEmpty` (`body`, inkMuted) + nút "Add habit".
  - Stream chưa có dữ liệu: chỉ hiện tiêu đề, không hiện spinner.
  - Chạm vào thẻ thì mở `showHabitActionsSheet`.
- **`add_habit_sheet.dart`**: `Future<void> showAddHabitSheet(BuildContext context)`.
  - Nội dung:
    1. Tiêu đề `title` "Add habit".
    2. Nhãn `headline` "Habit", bên dưới là `SteadyTextField` (hint "No sugar", `maxLength: 40`, một dòng, `autofocus`, `textCapitalization.sentences`).
    3. Nhãn `headline` "Clean since", bên dưới là một ô bấm được, trông giống text field (cao tối thiểu 48), hiện `formatShortDate`. Bấm vào thì gọi `showDatePicker(firstDate: DateTime(today.year - 100), lastDate: today.toDateTime(), initialDate: ngày đang chọn)`.
    4. Nút primary lg block "Save habit".
  - Nút Save bị vô hiệu khi `normalizeHabitName == null` hoặc đang lưu.
  - Khi lưu: gọi `addHabit(today: services.today.value)` rồi đóng sheet. Lỗi thì hiện snackbar `saveError` và giữ sheet mở.
- **`habit_actions_sheet.dart`**: `Future<void> showHabitActionsSheet(BuildContext context, Habit habit)`.
  - Tiêu đề `title` là tên thói quen (tối đa 2 dòng, ellipsis). Hai nút md block, cách nhau 12.
  - "Reset streak" (secondary): gọi `resetStreak(id, today)`, đóng sheet, hiện snackbar `resetDone`.
  - "Delete habit" (danger): mở `showSteadyConfirmDialog(deleteHabitTitle, deleteHabitBody, delete, cancel)`. Nếu `true` thì gọi `deleteHabit` rồi đóng sheet; nếu không thì giữ nguyên.

### 6.4 Check-in
- **`check_in_rules.dart`**
  - `enum Mood { awful(1), low(2), okay(3), good(4), great(5); final int value; static Mood fromValue(int v); }`: ngoài 1..5 thì ArgumentError.
  - `const kCheckInNoteMaxChars = 140;`
  - `String? normalizeCheckInNote(String raw)`: thay mọi `\r\n`, `\r`, `\n` bằng dấu cách rồi trim; rỗng thì `null`; dài quá 140 grapheme thì ArgumentError.
  - `enum Greeting { morning, afternoon, evening }` và `Greeting greetingFor(DateTime localNow)` theo khung giờ ở Q9.
- **`CheckInScreen`** (StatefulWidget). State gồm: `Mood? mood`, `TextEditingController note`, `bool dirty`, `bool saving`.
  - Khi `initState` và mỗi lần `today` đổi: nếu `!dirty` thì đọc `getForDate(today)` và điền sẵn mood + note (rồi `dirty = false`). Nếu `dirty` thì giữ nguyên bản nháp.
  - Bố cục là `Column` gồm hai phần:
    - `Expanded(SingleChildScrollView(...))`, padding 32 trên và 20 hai bên, khoảng cách 24, gồm:
      1. Ngày `formatLongDate` (`label`, inkMuted); cách 4; lời chào (`display`).
      2. "How was today?" (`headline`); cách 12; `MoodPicker`.
      3. "One line about today" (`headline`); cách 8; `SteadyTextField` (`minLines`/`maxLines` 3, `maxLength` 140, `textInputAction.done`, `FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' ')`); cách 8; bộ đếm `noteCounter` (`caption`, inkMuted, chữ số đều độ rộng, căn phải), đếm bằng `note.text.characters.length`.
      4. Nếu có chuỗi chính: `SteadyChip` tide, icon `sprout`, nhãn `streakChip(daysClean, name)`.
    - `Padding(20)` chứa nút primary lg block "Save check-in", đặt **ngoài** vùng cuộn để bàn phím không che. Không dùng `IntrinsicHeight` hay `Spacer` trong vùng cuộn.
  - Chạm vào nền thì unfocus.
  - Nút Save bị vô hiệu khi `mood == null` hoặc đang lưu.
  - Khi lưu:
    1. `services.today.refresh()` rồi lấy `date = today.value`.
    2. Gọi `saveForDate`.
    3. `dirty = false`, unfocus, hiện snackbar `checkInSaved`.
    4. Nếu lỗi: snackbar `saveError`, giữ nguyên bản nháp.
    5. Trong `finally` đặt `saving = false`.

---

## 7. Copy (`lib/l10n/app_en.arb`)

Mọi chữ phải theo `design/steady-ds/README.md`, mục "Giọng văn". MỚI = chưa có trong thiết kế (Q10).

| key | text |
|---|---|
| tabFocus / tabTimer / tabStreaks / tabMoney / tabCheckIn | Focus / Timer / Streaks / Money / Check-in |
| placeholderBody (MỚI) | This part of Steady isn't ready yet. |
| addHabit | Add habit |
| streaksEmpty (MỚI) | Add a habit you want to leave behind. |
| streakDayUnit | `{count, plural, =1{day} other{days}}` |
| streakSince | Since {date} |
| milestoneNext | `Next: {target, plural, =1{1 day} other{{target} days}} · {remaining} to go` |
| habitNameLabel (MỚI) / habitNameHint | Habit / No sugar |
| cleanSinceLabel (MỚI) / saveHabit (MỚI) | Clean since / Save habit |
| resetStreak / resetDone | Reset streak / That's okay. Day 1 starts now. |
| deleteHabit (MỚI) | Delete habit |
| deleteHabitTitle (MỚI) | Delete {habit}? |
| deleteHabitBody (MỚI) | This removes the habit and its count. It can't be undone. |
| cancel (MỚI) / delete (MỚI) | Cancel / Delete |
| greetingMorning (MỚI) / greetingAfternoon (MỚI) / greetingEvening | Good morning / Good afternoon / Good evening |
| howWasToday | How was today? |
| moodAwful … moodGreat | Awful / Low / Okay / Good / Great |
| noteLabel | One line about today |
| noteCounter | {count} / {max} |
| saveCheckIn | Save check-in |
| checkInSaved (MỚI) | Check-in saved. |
| saveError (MỚI) | Couldn't save. Try again. |
| streakChip | Day {count} · {habit} |

Placeholder dạng số (`count`, `target`, `remaining`, `max`) khai báo kiểu `int`.

---

## 8. Trường hợp biên bắt buộc xử lý

1. **Giờ mùa hè (DST) và múi giờ:** đếm ngày chỉ bằng `LocalDate.epochDay`. Không dùng `Duration.inDays` giữa hai `DateTime` theo giờ máy.
2. Ngày bắt đầu nằm ở tương lai (ví dụ đồng hồ máy bị chỉnh lùi) thì `daysClean` trả 0, không ra số âm. `addHabit` từ chối ngày tương lai.
3. App mở xuyên qua nửa đêm, hoặc quay lại từ nền: số ngày, lời chào và ngày của Check-in phải tự cập nhật (`TodayNotifier`).
4. `LocalDate.parse` từ chối `2026-02-30`, `2026-13-01`, `26-1-1` và chuỗi rỗng. Năm nhuận tính đúng.
5. Giới hạn 40 và 140 đếm theo **grapheme**: emoji ghép và tiếng Việt tổ hợp đều tính là 1 ký tự.
6. Chuỗi chỉ có khoảng trắng coi là rỗng. Ghi chú có xuống dòng (kể cả khi dán vào) thì đổi thành dấu cách. Tên thói quen không được có xuống dòng.
7. Không có lỗi overflow ở màn 360×800 với text scale 1.0 và 2.0 (tên dài, `countXl`, chip, nút, tab bar, MoodPicker).
8. Lưu Check-in hai lần trong cùng ngày, hoặc bấm Save liên tiếp, thì chỉ có một bản ghi.
9. Mood ngoài 1–5 bị chặn ở cả Dart lẫn ràng buộc CHECK của DB.
10. Ghi DB lỗi thì hiện snackbar `saveError` và không mất dữ liệu đang nhập.
11. Xoá phải qua xác nhận; bấm Cancel hoặc chạm ra ngoài thì không xoá. Reset hoặc xoá một id không tồn tại thì không crash.
12. Bản nháp Check-in còn nguyên khi chuyển tab. Sang ngày mới mà đang có bản nháp thì không ghi đè bản nháp.
13. Nút Back của Android: đóng sheet/dialog trước; đang ở tab khác Focus thì về Focus; đang ở Focus thì thoát app.
14. Bàn phím không che nút Save.
15. Không có snackbar nào gọi bằng `context` đã unmount.
16. Không chớp nền trắng lúc khởi động. Sheet và dialog không bị ám màu amber.
17. Vùng chạm ít nhất 48dp. Ngoài ra số ít/số nhiều phải đúng ("1 day" / "2 days"); không có thói quen nào thì không hiện chip trên Check-in.

---

## 9. Test

**Coder viết:**
- `test/helpers/test_app.dart`:
  - `Future<AppServices> pumpSteadyApp(WidgetTester t, {required Clock clock, Size size = const Size(360, 800), double textScale = 1.0})`:
    - Dùng `AppDatabase(NativeDatabase.memory())`; **không dùng** `createInBackground`.
    - Đặt `t.view.physicalSize`, `devicePixelRatio = 1`, `t.platformDispatcher.textScaleFactorTestValue`, và `addTearDown` để reset.
    - Đặt `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true`.
  - `Future<void> disposeSteadyApp(WidgetTester t, AppServices s)` làm theo thứ tự: `pumpWidget(SizedBox.shrink())`, `pump(Duration.zero)`, `s.dispose()`. Gọi hàm này ở cuối mỗi widget test để tránh lỗi "A Timer is still pending" của stream Drift.
  - Đồng hồ giả trong test: `var now = DateTime(2026, 10, 2, 21); final clock = Clock(() => now);`
- `test/app_smoke_test.dart`: app khởi động, thấy đủ 5 nhãn tab, không có exception.

**Tester viết** (theo mặc định A ở Q5; nếu người dùng chọn B thì các số ngày cộng thêm 1):
- **LocalDate:** parse hợp lệ và các chuỗi sai ở biên 4; `2028-02-28` → `2028-03-01` = 2; qua mốc DST (`2026-03-08`→`09`, `2026-11-01`→`02`) = 1; `fromDateTime` lúc 23:59:59 và 00:00:00.
- **streak_math:** `daysClean` cho hôm nay = 0, hôm qua = 1, ngày tương lai = 0. `nextMilestone(0)` = (1, 1, 0.0); `(7)` = (14, 7, 0.0); `(127)` = (180, 53, 37/90); `(364)` = (365, 1, …); `(365)` và `(1000)` = null.
- **habit_name và note:** trim; rỗng hoặc chỉ khoảng trắng → null; 40 grapheme có emoji `👨‍👩‍👧` vẫn hợp lệ, 41 thì không; 140 và 141 với ghi chú; xuống dòng; `Mood.fromValue(0)` và `(6)` ném lỗi; `greetingFor` lúc 04:59, 05:00, 11:59, 12:00, 17:59, 18:00.
- **formatting:** (en, en_GB) → `en_GB`; (en, de_DE) → `en`; `formatShortDate` cùng năm → "May 28", khác năm → "May 28, 2025"; `formatLongDate(2026-10-02)` → "Friday, October 2".
- **Repository** (Drift in-memory): thứ tự sắp xếp; reset, delete, và id không tồn tại → false; `addHabit` với tên rỗng hoặc ngày tương lai → ArgumentError (**đây là case bắt buộc phải thất bại**); lưu Check-in hai lần cùng ngày → còn 1 dòng với giá trị mới; khác ngày → 2 dòng; chèn mood 6 bằng SQL thô bị DB từ chối.
- **Widget** (clock 2026-10-02 21:00, thói quen "No smoking" bắt đầu 2026-05-28):
  - Thẻ lớn hiện "127", "Since May 28", "Next: 180 days · 53 to go".
  - Thêm thói quen qua sheet; Save bị vô hiệu khi tên rỗng.
  - Reset thì số về 0 và có snackbar `resetDone`. Delete → Cancel thì còn, Delete → Delete thì mất.
  - Đổi `now` sang ngày hôm sau rồi gọi `today.refresh()` thì số ngày +1.
  - Check-in: thấy "Friday, October 2" và "Good evening"; Save bị vô hiệu khi chưa chọn mood; gõ 150 ký tự thì chỉ giữ 140 và bộ đếm hiện "140 / 140"; lưu xong pump lại app thì mood và note được điền sẵn; chip hiện "Day 127 · No smoking"; không có thói quen thì không có chip.
  - Bản nháp còn nguyên sau khi chuyển tab rồi quay lại. Back ở tab Streaks thì về tab Focus.
  - Streaks và Check-in không có exception overflow ở text scale 2.0.
- **Đồng bộ token:** đọc `design/steady-ds/tokens.json`; mọi màu của 3 theme khớp `SteadyColors`; mọi kiểu chữ khớp `fontSize`, `height`, `weight` trong `SteadyText`.
- **Icon:** mỗi hằng trong `SteadyIcons` có file `assets/icons/<tên>.svg` tương ứng.

**Tiêu chí xong:**
- Mọi lệnh ở mục 2.3 trả mã 0, và `flutter analyze` báo "No issues found".
- `grep -rn "DateTime.now()" lib` không ra kết quả.
- `grep -rn "Color(0x" lib` chỉ ra kết quả trong `lib/core/theme/tokens.dart`.

---

## 10. Quy ước và file để bám theo

- **Dart:** `dart format`; lint theo `analysis_options.yaml` do `flutter create` sinh (flutter_lints); tên file snake_case, mỗi file một widget public. Component trùng tên với Material thì thêm tiền tố `Steady`; `StreakCard` và `MoodPicker` giữ tên như trong design system.
- **Giọng văn, màu, chữ, khoảng cách, trạng thái:** `design/steady-ds/README.md`.
- **Giá trị token:** `design/steady-ds/tokens.json`.
- **Hình dáng component:** `design/steady-ds/components/{Button,Chip,ProgressBar,StreakCard,MoodPicker,TabBar,Icon}/README.md` và `design/steady-ds/components/bundle.css` (class `.st-btn`, `.st-chip`, `.st-bar`, `.st-streak`, `.st-mood`, `.st-tabbar`, `.st-tab`). `bundle.js` chỉ để tham chiếu; không chép code React.
- **Bố cục màn hình:** `design/mockups/steady/Streaks.dc.html` và `design/mockups/steady/CheckIn.dc.html` (bỏ qua TabBar 4 tab trong đó).
- **Xử lý lỗi:** repository ném `ArgumentError` khi đầu vào sai; UI kiểm tra trước để không bao giờ gửi đầu vào sai xuống.
