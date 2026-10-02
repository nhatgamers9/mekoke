# Kế hoạch: GĐ3 phần 1, tab Money (theo dõi chi tiêu)

Yêu cầu gốc (lệnh /ship): "người dùng không dùng phần mềm để tích trữ tiền họ chỉ dùng phần mềm này để xem chi tiêu của bản thân thôi".
Mọi đường dẫn tính từ `/home/user/mekoke/`. Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `d88adf6`. Không commit, không push, không đổi nhánh.

---

## Câu hỏi đã trả lời

Người dùng trả lời "đồng ý" (2026-10-02), tức là nhận mọi phương án mặc định Q1–Q8 bên dưới. Không còn câu hỏi nào bỏ ngỏ; Coder làm đúng theo kế hoạch như đã viết.

**Q1. Hạn mức chi (ngân sách).**
- **Mặc định:** lần này không có hạn mức, không có "Left to spend", không có mục BUDGETS. Có làm hạn mức ở phần sau hay không thì hỏi lại khi tới đó.
- Lựa chọn khác:
  - (b) Làm ngay lần này một hạn mức tổng mỗi tháng do bạn tự đặt (không dựa trên thu nhập). Khi đó số lớn đổi thành "Left to spend"; vượt hạn mức thì hiện `rose` kèm "Over by …". Phải thêm màn đặt hạn mức, nên lần này phải bớt việc khác.
  - (c) Phần sau làm hạn mức cho từng danh mục (`BudgetRow`).
  - (d) Bỏ hẳn hạn mức khỏi lộ trình.

**Q2. Tiền tệ và số tiền.**
- **Mặc định:**
  - Lần đầu mở tab Money, app lấy tiền tệ theo vùng của máy (`en_US` ra USD, `de_DE` ra EUR, `ja_JP` ra JPY), rồi lưu cố định vào prefs `money.currency`. Đổi vùng của máy về sau thì tiền tệ không đổi theo. Màn đổi tiền tệ để GĐ5 (Settings).
  - Cách viết số (dấu nhóm, dấu thập phân) theo locale định dạng của app, cùng quy tắc với ngày tháng.
  - Phần nguyên nhập tối đa 9 chữ số, tức tối đa 999,999,999.99 với USD.
- Lựa chọn khác:
  - (b) Luôn dùng USD.
  - (c) Hỏi bạn chọn tiền tệ ở lần mở đầu (thêm một màn chọn).

**Q3. Danh mục chi.** Danh sách cố định trong code; chưa cho thêm danh mục riêng.
- **Mặc định, 12 mục:**
  - Hiện sẵn 7 mục giống mockup: Groceries, Eating out, Transport, Bills, Shopping, Health, Gifts.
  - Ô thứ 8 là "More". Bấm vào thì mở thêm Housing, Travel, Phone, Education, Other.
  - Không có danh mục thu nữa (Salary, Interest).
- Lựa chọn khác:
  - (b) Hiện cả 12 mục cùng lúc. Khi đó lưới thành 3 hàng và màn nhập phải cuộn ngay ở cỡ chữ 1.0.
  - (c) Đổi danh sách.

**Q4. Các trường của một khoản chi.**
- **Mặc định:** số tiền, danh mục, ngày, ghi chú.
  - Ngày mặc định là hôm nay. Chọn được ngày đã qua, không chọn được ngày tương lai.
  - Ghi chú một dòng, tối đa 60 ký tự.
- Không có nút cách trả (Card/Cash) như trên mockup.
- Lựa chọn khác: thêm cách trả Card/Cash. Khi đó màn nhập có thêm một nút, và dòng chi tiết thành "Card · 6:42 PM".

**Q5. Phần "xem chi tiêu" trên tab Money.**
- **Mặc định:** đặt ngay trên tab Money, không có màn riêng.
  - Số lớn "Spent this month".
  - Dòng "Last month: $X" ngay dưới, là tổng chi của cả tháng trước. Tháng trước không có khoản nào thì ẩn dòng này.
  - Mục BY CATEGORY: biểu đồ thanh ngang một màu `amber` như mockup Report. Mỗi danh mục có chi trong tháng này là một thanh, xếp từ lớn tới nhỏ. Tháng này chưa chi gì thì ẩn cả mục.
  - Chưa xem lại được từng tháng cũ. Màn Report riêng và xuất CSV để sau.
- Lựa chọn khác:
  - (b) Dòng so sánh tính cùng kỳ: chi từ đầu tháng trước tới cùng ngày trong tháng ("By this day last month: $X").
  - (c) Thêm màn Report riêng, có chip "This month / Last month" để xem cả danh mục của tháng trước.
  - (d) Lần này chưa làm BY CATEGORY và dòng tháng trước.

**Q6. Sửa và xoá.**
- **Mặc định:** chạm một dòng thì mở sheet có hai nút "Edit expense" và "Delete expense". Delete hỏi xác nhận, nút màu đỏ vì đây là xoá dữ liệu.
- Lựa chọn khác:
  - (b) Chỉ có xoá.
  - (c) Vuốt để xoá.

**Q7. Chọn danh mục trước khi lưu.**
- **Mặc định:** không chọn sẵn danh mục nào. Chưa chọn danh mục hoặc số tiền bằng 0 thì nút Save bị tắt, để tránh lưu nhầm danh mục.
- Lựa chọn khác: chọn sẵn Groceries như mockup.

**Q8. Bảng câu chữ ở §8.**
- **Mặc định:** dùng bảng ở §8. Các dòng ghi MỚI là câu chưa có trong thiết kế.
  - Màn danh sách đổi tên từ "Transactions" thành "Expenses".
  - Số tiền ở từng dòng và tổng mỗi ngày giữ dấu "−" như thiết kế `TransactionRow`. Tổng tháng này, tháng trước và số ở BY CATEGORY không có dấu.
- Lựa chọn khác: bỏ dấu "−" ở mọi nơi, vì app chỉ có khoản chi.

---

## 0. Quyết định đã chốt (không hỏi lại)

- Lần này làm Money (GĐ3 phần 1). Thông báo (GĐ2 phần 2) chưa làm.
- **Money là trình theo dõi chi tiêu. Chỉ ghi khoản chi.** Các phần sau bị bỏ khỏi thiết kế, không phải hoãn:
  - Khoản thu: nút Income, segmented Expense/Income, danh mục thu, dòng "Income this month", bộ lọc Expenses/Income, ô Income trên Report, màu `tide` cho số tiền thu.
  - Tích trữ: ô "Saved", Savings 20%, Envelopes ("Every dollar has a job"), 50/30/20, BudgetSetup ("Monthly take-home pay"). Tất cả đều tính từ thu nhập.
  - Chuyển tiền: dòng "To savings", bộ lọc Transfers.
  - "Left to spend" tính từ thu nhập.
- Dùng Drift. Chỉ theme Dark. 5 tab theo thứ tự cố định Focus, Timer, Streaks, Money, Check-in.
- **Không làm icon `settings`** trên mockup Money. Bỏ qua TabBar trong mockup.
- `rose` chỉ dùng cho xoá dữ liệu. Tiền luôn dùng phông sans, không dùng serif.
- App offline, không liên kết ngân hàng.
- Số tiền lưu bằng số nguyên dương theo đơn vị nhỏ nhất của tiền tệ (cent với USD, yên với JPY).
- Bài học từ vòng S3: mọi hàm hành động bất đồng bộ bắt đầu bằng `if (_busy) return;`. `_busy` được bật trước hộp thoại xác nhận.
- Không đụng 9 điểm "để sau" của lần trước.

---

## 1. Phạm vi lần này

**Làm:**
- DB schema v3: thêm bảng `money_entries`, có migration từ v1 và v2.
- Repository Money. Prefs lưu tiền tệ.
- Logic thuần: nhập số tiền bằng keypad, định dạng tiền, khoảng tháng, tổng, tổng theo danh mục, gom theo ngày.
- Component mới: `IconTile`, `Keypad`, `TransactionRow`, `BarChartRow`.
- Tab Money gồm:
  - tháng hiện tại và chip "Offline · no bank link";
  - "Spent this month" và dòng "Last month";
  - nút "Add expense";
  - mục BY CATEGORY;
  - 5 khoản gần nhất và nút "See all".
- Màn nhập/sửa khoản chi (route toàn màn hình), sheet ghi chú, chọn ngày.
- Màn Expenses: mọi khoản chi, gom theo ngày, mỗi ngày có tổng.
- Sheet hành động trên một dòng: sửa, xoá.

**Không làm:**
- Hạn mức (Q1), màn Report riêng, xem tháng khác.
- Ô tìm kiếm, cách trả, khoản định kỳ, xuất/nhập dữ liệu.
- Đổi tiền tệ, danh mục tự tạo.
- Icon Settings. Thông báo. Build APK.
- Không thêm package. Không thêm file SVG: `assets_and_copy_test` khoá đúng 67 icon.

---

## 2. Thứ tự làm và lệnh

Đặt `export PATH="/opt/flutter/bin:$PATH"` và làm việc trong `/home/user/mekoke`.

1. Chạy `flutter test` để xác nhận mốc **+722, 0 rớt**.
2. **Trước khi sửa `lib/data/database.dart`:**
   - Chép `drift_schemas/drift_schema_v2.json` ra scratchpad.
   - Chạy `dart run drift_dev schema dump lib/data/database.dart drift_schemas/`.
   - `diff` bản vừa dump với bản đã chép:
     - Khác ở phần bảng hoặc cột: **dừng lại**, ghi vào `.bangiao/thay-doi.md`, không sửa DB.
     - Chỉ khác ở `_meta`: ghi lại rồi làm tiếp.
3. Sửa DB theo §4.1, rồi chạy lần lượt:
   - `dart run build_runner build --delete-conflicting-outputs`
   - `dart run drift_dev schema dump lib/data/database.dart drift_schemas/` (ra `drift_schema_v3.json`)
   - `dart run drift_dev schema generate drift_schemas/ test/generated_migrations/` (ra `schema_v3.dart`; `schema.dart` có `versions = [1, 2, 3]`)
4. Làm §4.2 đến §7, rồi sửa ARB (§8) và chạy `flutter gen-l10n`.
5. Kiểm chứng:
   ```
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   flutter gen-l10n
   dart format lib test
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   TZ=America/New_York flutter test
   grep -rn "DateTime.now()" lib            # không được có kết quả
   grep -rn "Color(0x" lib                  # chỉ được có trong lib/core/theme/tokens.dart
   graphify update .                        # nếu có lệnh graphify (theo CLAUDE.md)
   ```

**Coder không sửa file test nào**, trừ các file sinh ra trong `test/generated_migrations/`.
- Sau khi Coder xong, các test rớt phải nằm trong danh sách §10.2.
- Coder ghi danh sách test rớt thực tế và mọi chỗ lệch kế hoạch (kèm lý do) vào `.bangiao/thay-doi.md`.

---

## 3. Danh sách file

| File | Việc |
|---|---|
| `drift_schemas/drift_schema_v3.json` | sinh ra, giữ trong repo |
| `test/generated_migrations/*` | sinh lại |
| `lib/data/money_types.dart` | mới, §4.2 |
| `lib/data/database.dart` (+ `database.g.dart`) | §4.1 |
| `lib/data/money_repository.dart` | mới, §4.3 |
| `lib/data/prefs_repository.dart` | thêm `loadCurrency` (§4.4) |
| `lib/core/services.dart` | thêm `money` (§4.5) |
| `lib/core/format/money_format.dart` | mới, §5.2 |
| `lib/core/format/formatting.dart` | thêm `formatMonth` (§5.2) |
| `lib/features/money/amount_input.dart` | mới, §5.1 |
| `lib/features/money/money_math.dart` | mới, §5.3 |
| `lib/features/money/money_labels.dart` | mới, §5.4 |
| `lib/features/money/money_screen.dart` | mới, §7.1 |
| `lib/features/money/entry_editor_screen.dart` | mới, §7.2 |
| `lib/features/money/note_sheet.dart` | mới, §7.3 |
| `lib/features/money/entries_screen.dart` | mới, §7.4 |
| `lib/features/money/entry_actions_sheet.dart` | mới, §7.5 |
| `lib/features/money/entry_row.dart` | mới, §7.6 |
| `lib/features/shell/home_shell.dart` | tab 3 thành `MoneyScreen(isActive: _index == 3)` |
| `lib/ui/components/icon_tile.dart`, `keypad.dart`, `transaction_row.dart`, `bar_chart_row.dart` | mới, §6 |
| `lib/ui/components/steady_icon.dart` | thêm hằng icon (§6) |
| `lib/l10n/app_en.arb` (+ file sinh ra) | §8 |

`PlaceholderScreen` giữ nguyên, vì tab Focus vẫn dùng.

---

## 4. Dữ liệu

### 4.1 `database.dart`, schema v3
```dart
import 'money_types.dart';

@DataClassName('MoneyEntry')
class MoneyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMinor =>
      // ignore: recursive_getters
      integer().check(amountMinor.isBetweenValues(1, kMaxAmountMinor))();
  TextColumn get category => textEnum<MoneyCategory>()();
  TextColumn get note => text().nullable()();
  TextColumn get date => text().map(const LocalDateConverter())();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Habits, CheckIns, Fasts, Prefs, MoneyEntries])
// schemaVersion => 3
// onUpgrade: giữ nguyên khối `if (from < 2) {...}`; thêm
//   if (from < 3) { await m.createTable(moneyEntries); }
```
- Không đổi `Habits`, `CheckIns`, `Fasts`, `Prefs`.
- **Không có cột `kind`.** Mọi dòng của bảng đều là khoản chi.
- Tên bảng SQL là `money_entries`, lớp là `MoneyEntry`. Không đặt tên `Expense`, để sau này nếu cần thêm loại khác thì chỉ cần một migration `addColumn` có giá trị mặc định. Lần này không làm gì thêm cho việc đó.
- Không đặt tên `Transaction` hay `Transactions`, để tránh trùng với API transaction của Drift.
- Danh mục được lưu bằng `name` của enum, nên sau này không được đổi tên giá trị enum.

### 4.2 `lib/data/money_types.dart` (mới)
Đặt trong `lib/data`, không đặt trong `lib/features`. Lý do: Reviewer đã ghi nhận việc tầng data import tầng feature là nợ kỹ thuật, nên không tạo thêm.
```dart
/// Thứ tự khai báo là thứ tự trên lưới chọn; 7 mục đầu hiện sẵn.
enum MoneyCategory {
  groceries, eatingOut, transport, bills, shopping, health, gifts,
  housing, travel, phone, education, other,
}

const kMaxAmountMinor = 999999999999;
const kMoneyNoteMaxChars = 60;

/// Giống normalizeCheckInNote: xuống dòng thành dấu cách, trim, rỗng thì null;
/// quá kMoneyNoteMaxChars grapheme thì ném ArgumentError.
String? normalizeMoneyNote(String raw);
```

### 4.3 `lib/data/money_repository.dart` (theo kiểu `habit_repository.dart`)
```dart
class MoneyRepository {
  MoneyRepository(AppDatabase db, Clock clock);
  Stream<List<MoneyEntry>> watchAll();
  Stream<List<MoneyEntry>> watchRecent({int limit = 5});
  Stream<List<MoneyEntry>> watchBetween(LocalDate from, LocalDate to); // gồm cả hai đầu
  Future<MoneyEntry> add({required int amountMinor, required MoneyCategory category,
      required LocalDate date, String? note});
  Future<bool> update(int id, {required int amountMinor, required MoneyCategory category,
      required LocalDate date, String? note});
  Future<bool> delete(int id);
}
```
- **Thứ tự** của mọi stream: `date DESC, createdAt DESC, id DESC`.
- **`watchBetween`** so chuỗi ISO: `t.date.isBetweenValues(from.toIso(), to.toIso())`.
- **Kiểm đầu vào** ở `add` và `update`, sai thì ném `ArgumentError`:
  - `amountMinor` nằm ngoài [1, `kMaxAmountMinor`].
  - Ghi chú quá dài (qua `normalizeMoneyNote`).
- **Ghi chú** luôn được lưu ở dạng đã chuẩn hoá.
- **`add`:** `createdAt = clock.now()`.
- **`update`:** ghi lại amountMinor, category, date, note. **Không đổi `createdAt`.** Trả `false` khi không có `id`.
- **`delete`:** trả `false` khi không có `id`.
- Repository không kiểm "ngày không ở tương lai"; UI đã chặn.

### 4.4 `prefs_repository.dart`
```dart
static const _currencyKey = 'money.currency';
/// Có giá trị hợp lệ (khớp ^[A-Z]{3}$) thì trả về giá trị đó.
/// Không có hoặc không hợp lệ: ghi [fallback] (lỗi ghi thì bỏ qua) rồi trả [fallback].
/// Lỗi đọc: trả [fallback], không ghi. Hàm này không bao giờ ném lỗi.
Future<String> loadCurrency({required String fallback});
```

### 4.5 `services.dart`
Thêm `final MoneyRepository money;`, khởi tạo bằng `MoneyRepository(db, clock)`. Không đổi gì khác. `test/helpers/test_app.dart` không cần sửa.

---

## 5. Logic thuần (không có widget; test được bằng unit test)

### 5.1 `lib/features/money/amount_input.dart`
```dart
const kAmountMaxIntegerDigits = 9;

@immutable
class AmountInput {
  static const empty = AmountInput._('');
  factory AmountInput.fromMinor(int minor, int decimals);
  final String text;          // dạng chuẩn: "", "0", "12", "12.", "12.4"
  bool get isEmpty;
  bool get hasSeparator;      // có '.'
  int get fractionDigits;     // số chữ số sau '.'
  AmountInput press(String key, {required int decimals}); // key: '0'–'9', '.', 'del'; key khác thì ArgumentError
  int toMinor(int decimals);  // "" ra 0; "12." với 2 ra 1200; "12.4" với 2 ra 1240
  // ==, hashCode theo text
}

/// Chuỗi hiển thị trên màn nhập. Quy tắc ở cuối mục này.
String formatAmountInput(MoneyFormat m, AmountInput input);
```

Quy tắc `press`:

| Phím | Điều kiện | Kết quả |
|---|---|---|
| chữ số | đã có '.' và `fractionDigits >= decimals` | giữ nguyên |
| chữ số | đã có '.' và còn chỗ | thêm vào cuối |
| chữ số | chưa có '.' và `text == "0"` | thay bằng chữ số đó ("0" rồi "0" vẫn là "0") |
| chữ số | chưa có '.' và đã đủ 9 chữ số | giữ nguyên |
| chữ số | còn lại | thêm vào cuối |
| `.` | `decimals == 0` hoặc đã có '.' | giữ nguyên |
| `.` | `text` rỗng | thành "0." |
| `.` | còn lại | thêm vào cuối |
| `del` | | bỏ ký tự cuối; rỗng thì giữ nguyên |

`fromMinor`:
- `minor <= 0` thì ra `empty`.
- `decimals == 0` thì ra "1200".
- Còn lại thì luôn đủ chữ số thập phân: (1240, 2) ra "12.40"; (5, 2) ra "0.05".

`formatAmountInput`:
- Rỗng: `m.formatScaled(0, 0)`, ra "$0".
- Còn lại:
  - Đặt `k = input.fractionDigits`, rồi lấy `m.formatScaled(input.toMinor(k), k)`.
  - Ví dụ: "12" ra "$12", "12.4" ra "$12.4", "12.40" ra "$12.40".
  - Nếu chuỗi nhập kết thúc bằng '.', chèn `m.decimalSeparator` ngay sau chữ số ASCII cuối cùng của chuỗi đã định dạng. Ví dụ "12." ra "$12."; với `de` và EUR thì ra "12, €".

### 5.2 `lib/core/format/money_format.dart` và `formatMonth`
`core` không import `features`.
```dart
class MoneyFormat {
  factory MoneyFormat(String localeTag, String currencyCode); // cache theo cặp (tag, code)
  final String currencyCode;
  int get decimals;              // = decimalsFor(currencyCode)
  String get decimalSeparator;   // NumberFormat.decimalPattern(numTag).symbols.DECIMAL_SEP
  String format(int minor);      // = formatScaled(minor, decimals). Ví dụ 1240 ra "$12.40"
  String formatScaled(int value, int fractionDigits); // value / 10^fractionDigits, đúng fractionDigits chữ số thập phân, kèm ký hiệu
  static String currencyForLocale(String deviceLocaleTag); // không xác định được thì 'USD'
  static int decimalsFor(String currencyCode);  // NumberFormat.simpleCurrency(locale: 'en', name: code).decimalDigits ?? 2
}
```
- `numTag = Intl.verifiedLocale(localeTag, NumberFormat.localeExists, onFailure: (_) => 'en')`.
- `formatScaled` dùng `NumberFormat.simpleCurrency(locale: numTag, name: currencyCode, decimalDigits: fractionDigits)`. Cache `NumberFormat` theo `fractionDigits` trong instance.
- `format` và `formatScaled` không bao giờ thêm dấu; dấu "−" do `money_labels` thêm.
- **`currencyForLocale`:**
  - `v = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (_) => 'en')`, rồi lấy `NumberFormat.simpleCurrency(locale: v).currencyName ?? 'USD'`.
  - Ở widget, `tag` lấy từ `WidgetsBinding.instance.platformDispatcher.locale.toString()`, tức vùng của máy, **không** lấy từ `formatLocaleOf`. Lý do: máy `vi_VN` thì `formatLocaleOf` trả 'en', sẽ ra USD sai.

Trong `formatting.dart`, thêm `String formatMonth(LocalDate d, String tag)`: dùng `DateFormat.MMMM(tag)`, cache theo tag như các hàm sẵn có. Kết quả ví dụ "October".

### 5.3 `lib/features/money/money_math.dart`
```dart
typedef DateRange = (LocalDate, LocalDate);
DateRange monthRange(LocalDate d);              // (ngày 1, ngày cuối) của tháng chứa d
LocalDate previousMonth(LocalDate d);           // ngày 1 của tháng trước
bool inRange(LocalDate d, DateRange r);         // gồm cả hai đầu
int totalOf(Iterable<MoneyEntry> entries);      // tổng amountMinor

@immutable
class CategoryTotal {
  const CategoryTotal(this.category, this.amount);
  final MoneyCategory category;
  final int amount;
  // ==, hashCode
}
/// Chỉ gồm danh mục có tổng > 0. Xếp tổng giảm dần; bằng nhau thì theo thứ tự khai báo enum.
List<CategoryTotal> totalsByCategory(Iterable<MoneyEntry> entries);

@immutable
class DayGroup {
  const DayGroup(this.date, this.entries);
  final LocalDate date;
  final List<MoneyEntry> entries;
  int get total;                                // totalOf(entries)
}
/// Giữ thứ tự đầu vào, gom các dòng liền nhau cùng date.
List<DayGroup> groupByDay(List<MoneyEntry> sorted);
```
- `LocalDate(y, 0, 1)` ném lỗi, nên `previousMonth` phải tự xử lý tháng 1: tháng 1 thì ra ngày 1 tháng 12 năm trước.
- Ngày cuối tháng: `DateTime.utc(y, m + 1, 0).day`.

### 5.4 `lib/features/money/money_labels.dart` (hàm, không có widget)
```dart
String categoryLabel(AppLocalizations l10n, MoneyCategory c);
String categoryIcon(MoneyCategory c);
String expenseAmount(AppLocalizations l10n, MoneyFormat m, int minor); // = l10n.amountExpense(m.format(minor))
String entryTitle(AppLocalizations l10n, MoneyEntry e);
String? entryDetail(AppLocalizations l10n, MoneyEntry e, {required String tag, required bool use24h});
String dayHeader(AppLocalizations l10n, LocalDate d, LocalDate today, String tag);
String dateLabel(AppLocalizations l10n, LocalDate d, LocalDate today, String tag);
```

Bảng danh mục:

| Danh mục | Nhãn | Icon |
|---|---|---|
| groceries | catGroceries | `shopping-cart` |
| eatingOut | catEatingOut | `coffee` |
| transport | catTransport | `car` |
| bills | catBills | `zap` |
| shopping | catShopping | `shirt` |
| health | catHealth | `heart-pulse` |
| gifts | catGifts | `gift` |
| housing | catHousing | `house` |
| travel | catTravel | `plane` |
| phone | catPhone | `smartphone` |
| education | catEducation | `graduation-cap` |
| other | catOther | `receipt` |

Quy tắc của các hàm:
- **`entryTitle`:** có ghi chú thì là ghi chú; không có thì là nhãn danh mục.
- **`entryDetail`:**
  - `time = formatClockTime(createdAt, tag, use24h: use24h)`. Chỉ có `time` khi `LocalDate.fromDateTime(createdAt) == date`.
  - Có ghi chú và có time: `l10n.entryDetailLine(category, time)`.
  - Có ghi chú, không có time: nhãn danh mục.
  - Không ghi chú, có time: `time`.
  - Không ghi chú, không có time: `null`.
- **`dayHeader`:** `dayToday` cho hôm nay, `dayYesterday` cho hôm qua. Ngày khác thì `formatShortDate(d, today, tag).toUpperCase()`, ví dụ "OCT 1" hoặc "DEC 31, 2025".
- **`dateLabel`:** `dateToday`, `dateYesterday`; ngày khác thì `formatShortDate(d, today, tag)`.

---

## 6. Component mới (`lib/ui/components/`)

Nguồn hình dáng:
- `design/steady-ds/components/{IconTile,Keypad,TransactionRow}/README.md`.
- `bundle.css` (`.st-itile`, `.st-keypad`/`.st-key`, `.st-listrow`/`.st-txn`) và `bundle.js`.
- Phần `<figure>` "Spending by category" trong `design/mockups/money/Report.dc.html`, cho `BarChartRow`.

Quy ước:
- Code mẫu để chép quy ước: `steady_segmented_control.dart` (Semantics của mục chọn một, vùng chạm 48), `steady_icon_button.dart`, `steady_stepper.dart` (hàng nền `surface`, viền dưới `line`, tham số `divider`), `steady_progress_bar.dart` (vẽ thanh).
- Tên không có tiền tố `Steady`, vì không trùng widget nào của Material (cùng kiểu với `TimerRing`, `StreakCard`).

**`SteadyIcons`** thêm 15 hằng sau. Mọi file đều đã có trong `assets/icons/`.
- `lock`, `calendar`, `delete`, `receipt`.
- `shoppingCart`, `coffee`, `car`, `zap`, `shirt`, `heartPulse`, `gift`, `house`, `plane`, `smartphone`, `graduationCap`.
- Giá trị là tên file kebab-case, ví dụ `'shopping-cart'`.
- `plus`, `x`, `notebookPen` đã có sẵn.

### `IconTile` (`icon_tile.dart`)
```dart
IconTile({required String icon, required String label, required bool? selected, required VoidCallback onTap})
```
- **`selected`:**
  - `null` là ô hành động (ô "More"). Semantics chỉ có `button` và `label`.
  - Khác `null`: Semantics có `button`, `selected`, `inMutuallyExclusiveGroup`, `label`, `onTap`, `excludeSemantics`, giống `_SegmentItem`.
- **Vùng chạm:** cả ô, bằng `Material(transparent)` + `InkWell(borderRadius md)`. Rộng bằng ràng buộc cha.
- **Bố cục:** `Column(center)`, đệm dọc `s2`.
  - Đĩa tròn 64. Thường: nền `surface`, icon 26 màu `ink`. Đang chọn: nền `amberSoft`, viền trong 2px `amber`, icon `amber`.
  - Cách `s2`.
  - Nhãn: `caption`, căn giữa, `maxLines: 2`, ellipsis. Thường màu `inkMuted`, đang chọn màu `ink`.

### `Keypad` (`keypad.dart`)
```dart
Keypad({required ValueChanged<String> onKey, required String decimalSeparator,
        required String semanticLabel, required String deleteLabel, bool decimalEnabled = true})
```
- Bọc ngoài bằng `Semantics(container: true, label: semanticLabel)`.
- 4 hàng × 3 cột theo thứ tự `1 2 3 / 4 5 6 / 7 8 9 / . 0 del`. Hàng và cột cách nhau `s2`; các phím `Expanded`.
- **Phím:** cao 56, bo `md`, nền `surface`.
  - Chữ: Figtree 24/28 w500 (`SteadyText.headline.copyWith(fontSize: 24, height: 28 / 24, fontWeight: w500, fontVariations: [FontVariation('wght', 500)])`), màu `ink`, bọc `FittedBox(scaleDown)`.
  - Mỗi phím: `Semantics(button, label, onTap, excludeSemantics)`.
- **Phím '.':** hiển thị `decimalSeparator` nhưng gửi `'.'`. Khi `!decimalEnabled` thì `Opacity 0.4`, `onTap` null, Semantics `enabled: false`.
- **Phím `del`:** nền trong suốt, icon `delete` 24 màu `inkMuted`, nhãn semantics `deleteLabel`, gửi `'del'`.

### `TransactionRow` (`transaction_row.dart`)
```dart
TransactionRow({required String icon, required String title, String? detail, required String amount,
                VoidCallback? onTap, bool divider = true})
```
Không có tham số `kind`: chỉ có khoản chi.
- **Khung:** `MergeSemantics` > `Material(surface)` > `InkWell(onTap)` > hàng cao tối thiểu 64, đệm 12/16. Nếu `divider` thì viền dưới 1px màu `line`.
- **Nội dung hàng:**
  - Đĩa 40 nền `surface2`, icon 20 màu `ink`.
  - Cách `s3`, rồi `Expanded` cột chữ: `title` (`body`, `ink`) và `detail` (`label`, `inkMuted`). Cả hai `maxLines: 1`, ellipsis.
  - Cách `s3`, rồi số tiền: `bodyStrong`, chữ số đều độ rộng (`FontFeature.tabularFigures()`), `maxLines: 1`, màu `ink`.
- **Chống tràn:** số tiền bọc `ConstrainedBox(maxWidth: 50% bề rộng hàng)` (lấy qua `LayoutBuilder`) + `FittedBox(scaleDown, centerRight)`.

### `BarChartRow` (`bar_chart_row.dart`)
```dart
BarChartRow({required String label, required String value, required double fraction})
```
- Bọc `MergeSemantics`. Thanh chỉ để trang trí, không có semantics riêng.
- `Column(stretch)`:
  - `Text(label)`: `label`, `ink`, `maxLines: 1`, ellipsis.
  - Cách `s1`.
  - `LayoutBuilder`. Đặt `w = maxWidth`, `reserve = w / 3`, `maxBar = w − reserve − s2`, `f = fraction` (NaN thì 0, kẹp vào [0, 1]).
  - `bar = f == 0 ? 0 : max(4, maxBar × f)`.
  - `Row(crossAxisAlignment: center)` gồm:
    - Thanh: rộng `bar`, cao 12, màu `amber`, `BorderRadius.horizontal(right: Radius.circular(4))` (theo mockup Report).
    - Cách `s2`.
    - `Expanded(Align(centerLeft, FittedBox(scaleDown, Text(value))))`: `label`, chữ số đều độ rộng, `ink`, `maxLines: 1`.
- Nhãn số luôn nằm ngay sau đầu thanh. Thanh dài nhất vẫn chừa đủ `reserve` cho nhãn số.

---

## 7. Màn hình (`lib/features/money/`)

Quy ước chung:
- Lấy `Navigator`/`l10n` trước `await` và kiểm `mounted` sau mỗi `await`.
- Đồng hồ chỉ lấy qua `services.clock`; ngày qua `services.today`.
- `MoneyFormat` tạo trong `build` bằng `MoneyFormat(formatLocaleOf(context), currency)`.

### 7.1 `MoneyScreen({required bool isActive})`
- **Mở lần đầu:** chép cách `TimerScreen` dùng `_opened`. Trước lần đầu `isActive == true` thì trả `SizedBox.shrink()` và không mở stream nào.
- Khi đã mở thì dựng widget private `_MoneyHome` (stateful, cùng file).
- **`initState` của `_MoneyHome`:**
  - Gọi `prefs.loadCurrency(fallback: MoneyFormat.currencyForLocale(<vùng của máy>))`.
  - Nghe `watchRecent()`.
  - Nghe `watchBetween(previousMonth(today), monthRange(today).$2)`: một stream cho cả tháng trước và tháng này.
  - Nghe `services.today` và gọi `setState` mỗi khi ngày đổi. Nếu tháng cũng đổi thì huỷ stream hai tháng, đặt danh sách về `null`, rồi nghe khoảng mới.
  - Lỗi stream thì đặt `_loadFailed = true`, **không** nuốt lỗi.
  - Huỷ mọi thứ trong `dispose`.
- **Số liệu tính trong `build`:**
  - `thisMonth` là các dòng có `inRange(date, monthRange(today))`.
  - `lastMonth` là các dòng có `inRange(date, monthRange(previousMonth(today)))`.
  - `spent = totalOf(thisMonth)`, `last = totalOf(lastMonth)`, `cats = totalsByCategory(thisMonth)`.
- **Vùng cuộn** (`SingleChildScrollView`, đệm LTRB 20/32/20/24, `Column(stretch)`):
  1. `Text(tabMoney, display, ink)`. Phần này luôn hiện.
  2. Nếu `_loadFailed`: `s4` + `SteadyInlineStatus(moneyLoadError, error)`. Dừng ở đây.
  3. Chưa có đủ tiền tệ, danh sách hai tháng và danh sách gần đây: dừng ở đây (không có spinner).
  4. `s4`, rồi `Wrap(alignment: spaceBetween, crossAxisAlignment: center, spacing/runSpacing s2)` gồm:
     - `formatMonth(today)` (`label`, `inkMuted`).
     - `SteadyChip(neutral, icon lock, moneyOffline)`.
  5. `s4`, rồi:
     - `spentThisMonth` (`label`, `inkMuted`).
     - `FittedBox(scaleDown, centerLeft)` chứa `format(spent)` (`moneyXl`, `ink`, `maxLines: 1`).
     - Chỉ khi `last > 0`: `spentLastMonth(format(last))` (`label`, `inkMuted`).
  6. `s4`, rồi `SteadyButton(primary, lg, block, icon plus, addExpense)`. Bấm thì push `EntryEditorScreen(currency: …)` bằng `MaterialPageRoute`. Route phủ cả thanh tab.
  7. Chỉ khi `cats` khác rỗng:
     - `s6`, `Text(byCategoryHeader, overline, inkMuted)`, rồi `s2`.
     - Khung nền `surface`, bo `lg`, đệm `s4`. Bên trong là `Column` các `BarChartRow`, cách nhau `s3`.
     - Mỗi `BarChartRow` có `label: categoryLabel`, `value: format(amount)`, `fraction: amount / cats.first.amount`.
  8. `s6`, rồi `Row`:
     - `Expanded(Text(recentHeader, overline, inkMuted))`.
     - Nếu có dòng nào: `SteadyButton(ghost, md, seeAll)`, bấm thì push `EntriesScreen(currency: …)`.
  9. `s2`, rồi một trong hai:
     - Chưa có dòng: `Text(moneyEmpty, body, inkMuted)`.
     - Có dòng: `ClipRRect(lg)` + `Column` các `EntryRow`. Dòng cuối `divider: false`. Chạm thì `showEntryActionsSheet`.
- **Tự kiểm fake-async:** Coder tự kiểm bằng một widget test tạm (xoá trước khi bàn giao) rằng các thao tác sau không treo trong vùng fake-async của widget test:
  - Mở tab Money lần đầu (lúc này có ghi prefs).
  - Lưu một khoản.
  - Xoá một khoản.

  Nếu treo thì ghi rõ vào `thay-doi.md`. Không được bỏ lần ghi prefs để né lỗi.

### 7.2 `EntryEditorScreen({required String currency, MoneyEntry? entry})`
`entry` khác `null` là chế độ sửa.

**State:**
- `_amount` (`AmountInput`), `MoneyCategory? _category`, `LocalDate _date`, `String? _note`, `bool _showAll`, `_busy`, `String? _error`.
- `d = MoneyFormat.decimalsFor(currency)`. Không phụ thuộc `context`, nên dùng được trong `initState`.
- Khởi tạo:
  - Có `entry`: lấy từ `entry`, số tiền qua `AmountInput.fromMinor`.
  - Không có: `empty`, `null`, `today`, `null`.
  - `_showAll = true` khi danh mục đang chọn không thuộc 7 mục đầu.

**Bố cục** (`Scaffold` > `SafeArea` > `Column`):
1. **Hàng trên, cố định.** Đệm LTRB 20/12/20/0. `Row` gồm:
   - `SteadyIconButton(plain, x, close)`, bấm thì `maybePop`.
   - `s2`, rồi `Expanded(Text(entry == null ? addExpense : editExpense, title, ink, maxLines 1, ellipsis))`.
2. **`Expanded(SingleChildScrollView)`.** Đệm LTRB 20/12/20/12, các khối cách `s3`:
   - **Khối số tiền** (căn giữa):
     - `FittedBox(scaleDown)` chứa `formatAmountInput(money, _amount)` (`moneyXl`, `ink`), bọc `Semantics(liveRegion: true)`.
     - Cách `s1`, rồi nhãn danh mục, hoặc `chooseCategory` khi chưa chọn (`label`, `inkMuted`).
   - **Lưới danh mục:**
     - Bọc `Semantics(container, label: categoryLabel)`.
     - `LayoutBuilder` tính bề rộng ô = (maxWidth − 3·`s1`)/4, rồi `Wrap(spacing/runSpacing s1)` các `IconTile`.
     - Khi `!_showAll`: 7 mục đầu, cộng ô `IconTile(plus, categoryMore, selected: null)`. Bấm ô này thì `_showAll = true`.
     - Khi `_showAll`: cả 12 mục.
   - **Hàng hai nút** (`Row`, hai `Expanded` cách nhau `s2`, cả hai là secondary `md`):
     - Icon `calendar`, nhãn `dateLabel(_date)`. Nhãn dựng lại khi `today` đổi (`ValueListenableBuilder`).
     - Icon `notebookPen`, nhãn là `_note ?? noteButton`.
3. **Vùng dưới, cố định.** Đệm LTRB 20/12/20/24, gồm lần lượt:
   - `Keypad(decimalEnabled: d > 0, decimalSeparator: money.decimalSeparator, semanticLabel: keypadLabel, deleteLabel: keypadBackspace)`.
   - `s3`.
   - Nếu có `_error`: `SteadyInlineStatus(error)` + `s3`.
   - Nút primary block `saveExpense`.

**Hành vi:**
- **Phím:** `_amount = _amount.press(key, decimals: d)` và xoá `_error`.
- **Chọn danh mục:** đặt `_category` và xoá `_error`.
- **Chọn ngày:** `showDatePicker`, theo mẫu ở `add_habit_sheet.dart`:
  - `firstDate: DateTime(today.year - 100)`.
  - `lastDate`: ngày lớn hơn trong hai ngày `today` và `_date`.
  - `initialDate: _date`.
- **Ghi chú:** `result = await showNoteSheet(context, initial: _note)`. Khác `null` thì `_note = normalizeMoneyNote(result)`.
- **Nút Save** bật khi `!_busy && _category != null && _amount.toMinor(d) > 0`.
- **`_save`:**
  1. Dòng đầu: `if (_busy) return;`.
  2. `_busy = true; _error = null`.
  3. Gọi `add` hoặc `update`. `update` trả `false` thì coi là lỗi.
  4. Thành công: pop route.
  5. Lỗi: `_error = saveError`; giữ nguyên mọi giá trị đang nhập.
  6. `finally`: nếu còn `mounted` thì `_busy = false`.
- X và Back đóng màn hình, không hỏi lại.

**Bắt buộc:** ở 360×800 với cỡ chữ 1.0, không cần cuộn vẫn thấy cả bốn khối: số tiền, hai hàng danh mục, hàng Date/Note, Keypad cùng nút Save. Ước tính: hàng trên 60, vùng cuộn 376 trên khoảng 400 px, vùng dưới khoảng 340.

### 7.3 `note_sheet.dart`
```dart
Future<String?> showNoteSheet(BuildContext context, {String? initial});
```
- Dùng `showSteadySheet`, chứa widget private có `TextEditingController` (nhớ dispose).
- Bố cục:
  - `Text(noteButton, title, ink)`, cách `s4`.
  - `SteadyTextField(hint: noteHint, maxLength: kMoneyNoteMaxChars, autofocus: true, textInputAction: done)`, cách `s4`.
  - Nút primary block `done`, bấm thì `pop(controller.text)`.
- Đóng sheet bằng cách khác thì trả `null`, nên ghi chú không đổi. Trả chuỗi rỗng nghĩa là xoá ghi chú.

### 7.4 `EntriesScreen({required String currency})`
- Nghe `watchAll()`. Lỗi thì hiện `moneyLoadError`.
- **Bố cục:** `Scaffold` > `SafeArea` > `Column` gồm:
  - Hàng trên (đệm LTRB 20/12/20/0): `SteadyIconButton(plain, x, close)`, `s2`, `Expanded(Text(expensesTitle, title, ink, maxLines 1))`.
  - `s4`, rồi `Expanded`:
    - Không có dòng nào: `Text(moneyEmpty)`, đệm ngang 20.
    - Có dữ liệu: `ListView.builder` (đệm LTRB 20/0/20/24). Mỗi item là một `DayGroup`; các nhóm cách nhau `s4`.
- **Mỗi nhóm:**
  - Hàng đầu: `Expanded(Text(dayHeader, overline, inkMuted))` và `Text(expenseAmount(group.total), label, inkMuted, chữ số đều độ rộng)`.
  - Cách `s2`, rồi `ClipRRect(lg)` + `Column` các `EntryRow`. Chạm thì mở sheet hành động.
- Nhãn ngày dựng lại khi `today` đổi.

### 7.5 `entry_actions_sheet.dart`
```dart
Future<void> showEntryActionsSheet(BuildContext context, {required MoneyEntry entry, required String currency});
```
Chép khung từ `lib/features/streaks/habit_actions_sheet.dart`.
- **Nội dung:**
  - `entryTitle` (`title`, `maxLines: 2`).
  - `s1`, rồi `expenseAmount(entry.amountMinor)` (`label`, `inkMuted`).
  - `s4`, rồi dòng lỗi nếu có.
  - Nút secondary `md` block `editExpense`, cách `s3`, rồi nút danger `md` block `deleteExpense`.
- **Edit:** lấy `navigator` trước, `navigator.pop()` để đóng sheet, rồi `navigator.push(EntryEditorScreen(currency: …, entry: entry))`.
- **Delete:** theo mẫu `_end` trong `fasting_view.dart`.
  1. `if (_busy) return;`, rồi `_busy = true` trước hộp thoại.
  2. `showSteadyConfirmDialog(title: deleteExpenseTitle, body: deleteExpenseBody, confirmLabel: delete, cancelLabel: cancel)`, để mặc định `destructive`.
  3. Huỷ: dừng.
  4. Xác nhận: `money.delete(id)`, rồi pop sheet. Kết quả `false` (dòng đã mất) cũng pop.
  5. Lỗi: `_error = saveError`, sheet vẫn mở.
  6. `finally`: `_busy = false`.

### 7.6 `EntryRow({required MoneyEntry entry, required MoneyFormat money, VoidCallback? onTap, bool divider = true})`
Dựng `TransactionRow` với:
- `icon`: `categoryIcon`.
- `title`: `entryTitle`.
- `detail`: `entryDetail`, trong đó `use24h = MediaQuery.alwaysUse24HourFormatOf`.
- `amount`: `expenseAmount(entry.amountMinor)`.

---

## 8. Câu chữ (`lib/l10n/app_en.arb`)

Bám mục "Giọng văn" trong `design/steady-ds/README.md`.
- Mọi placeholder số tiền, ngày, giờ, nhãn đều khai báo `String` (mẫu: `@streakSince`).
- Dùng lại các key có sẵn: `tabMoney`, `close`, `delete`, `cancel`, `saveError`.
- MỚI = chưa có trong thiết kế.

| key | text |
|---|---|
| moneyOffline | Offline · no bank link |
| spentThisMonth (MỚI) | Spent this month |
| spentLastMonth (MỚI) | Last month: {amount} |
| addExpense (MỚI) / editExpense (MỚI) | Add expense / Edit expense |
| byCategoryHeader (MỚI) | BY CATEGORY |
| recentHeader / seeAll | RECENT / See all |
| moneyEmpty (MỚI) | Your expenses will show up here. |
| moneyLoadError (MỚI) | Couldn't load your expenses. |
| expensesTitle (MỚI, thay "Transactions") | Expenses |
| dayToday / dayYesterday | TODAY / YESTERDAY |
| categoryLabel / chooseCategory (MỚI) / categoryMore | Category / Choose a category / More |
| catGroceries / catEatingOut / catTransport / catBills | Groceries / Eating out / Transport / Bills |
| catShopping / catHealth / catGifts | Shopping / Health / Gifts |
| catHousing / catTravel / catPhone / catEducation / catOther (MỚI) | Housing / Travel / Phone / Education / Other |
| dateToday / dateYesterday | Today / Yesterday |
| noteButton / noteHint (MỚI) / done (MỚI) | Note / What was it for? / Done |
| keypadLabel / keypadBackspace (MỚI) | Amount keypad / Delete last digit |
| saveExpense | Save expense |
| entryDetailLine (MỚI) | {category} · {time} |
| amountExpense | −{amount} |
| deleteExpense (MỚI) | Delete expense |
| deleteExpenseTitle (MỚI) / deleteExpenseBody (MỚI) | Delete this expense? / This removes it from your history. It can't be undone. |

`amountExpense` dùng dấu trừ U+2212, không dùng gạch nối.

---

## 9. Trường hợp biên bắt buộc xử lý

1. **Migration:** v1 lên v3 và v2 lên v3 giữ nguyên mọi dòng `habits`, `check_ins`, `fasts`, `prefs`. DB mới tạo thẳng ở v3, `user_version` = 3.
2. **Số tiền:**
   - Đúng mọi dòng trong bảng `press` ở §5.1.
   - "0.00" hay rỗng thì Save tắt.
   - Tiền tệ không có chữ số thập phân (JPY) thì phím '.' bị tắt.
   - Số lớn nhất nhập được là 999,999,999.99 (USD), không tràn bố cục ở mọi màn.
3. **Bấm Save hai lần** trước khung hình kế tiếp: chỉ tạo đúng một dòng, không hiện dòng lỗi.
4. **Ghi DB lỗi** khi lưu hoặc xoá: dòng lỗi hiện ngay tại chỗ, giá trị đang nhập còn nguyên, màn hoặc sheet không đóng.
5. **Tháng:**
   - Tổng tháng gồm cả ngày 1 và ngày cuối tháng. Khoản của tháng khác không vào tổng, nhưng vẫn hiện ở RECENT và Expenses.
   - Tháng 1 thì "Last month" là tháng 12 năm trước. Tháng 2 năm nhuận có 29 ngày.
   - Qua nửa đêm sang tháng mới khi app đang mở: "Spent this month" về 0, nhãn tháng đổi, "Last month" thành tổng của tháng vừa hết, BY CATEGORY ẩn.
6. **BY CATEGORY:**
   - Chỉ có danh mục có chi trong tháng này. Xếp từ lớn tới nhỏ; bằng nhau thì theo thứ tự danh mục ở §5.4.
   - Thanh lớn nhất dài đúng `maxBar`. Khoản rất nhỏ so với thanh lớn nhất vẫn có thanh rộng 4.
   - Đủ 12 danh mục với số tiền lớn nhất, ở cỡ chữ 2.0, vẫn không tràn.
   - Tháng này chưa chi gì thì ẩn cả mục.
7. **Dòng "Last month"** ẩn khi tổng tháng trước bằng 0.
8. **Chọn ngày:** không chọn được ngày sau hôm nay. Sửa một khoản có ngày sau hôm nay (đồng hồ máy bị lùi) không làm crash `showDatePicker`.
9. **Giờ ở dòng chi tiết** chỉ hiện khi khoản được tạo đúng vào ngày của nó. Sửa khoản không đổi `createdAt`. Máy đặt giờ 24h thì hiện "21:00".
10. **Nhóm theo ngày:** tiêu đề lần lượt là TODAY, YESTERDAY, "SEP 30", và "DEC 31, 2025" với năm khác. Tổng ngày bằng tổng các dòng, có dấu "−".
11. **Tiền tệ:**
    - Lưu một lần rồi cố định. Đổi vùng của máy về sau không đổi ký hiệu.
    - Giá trị trong prefs hỏng thì dùng tiền tệ theo vùng và ghi đè.
12. **Stream:** trước khi mở tab Money lần đầu thì không có stream Money nào chạy. Sau `dispose` không còn subscription nào.
13. **Bố cục:**
    - Không overflow ở 360×800 với cỡ chữ 1.0 và 2.0, cho mọi màn:
      - tab Money: rỗng; có dòng; số tiền lớn nhất; ghi chú 60 ký tự; đủ 12 thanh BY CATEGORY;
      - màn nhập: chưa mở và đã mở More;
      - Expenses, sheet hành động, sheet ghi chú với bàn phím 300 px.
    - Mọi vùng chạm (phím, ô danh mục, nút, dòng) tối thiểu 48dp.
    - Đúng ràng buộc "không cần cuộn" ở cuối §7.2.
14. **Màu:** mọi số tiền màu `ink`. Tab Money không dùng `tide`. `rose` chỉ có ở nút "Delete expense" và nút Delete trong hộp thoại.

---

## 10. Test

### 10.1 Mốc hiện tại
`flutter analyze` sạch. `flutter test`: **+722, 0 rớt** ở cả múi giờ mặc định lẫn `TZ=America/New_York`.

### 10.2 Test cũ sẽ đỏ vì đặc tả đổi (chỉ những test này, sau khi Coder xong)
- `test/widget/shell_navigation_test.dart`: "Focus and Money show the placeholder".
- `test/data/migration_test.dart`: có thể đỏ cả 8 test vì schema lên v3:
  - "the app database is at version 2"
  - "the generated helper knows both versions"
  - "the migrated schema is exactly the v2 schema"
  - "every habit and check-in row of v1 is kept as it was"
  - "the two new tables are there, empty and usable"
  - "an empty v1 database migrates too"
  - "is created straight at v2 with the same schema as the migration"
  - "has all four tables and starts empty"

Test nào khác rớt thì Coder phải sửa `lib/`, không được để lại.

### 10.3 Phân công
- **Coder:**
  - Được sửa toàn bộ `lib/`, ARB, `drift_schemas/`, và các file sinh ra trong `test/generated_migrations/`.
  - Không sửa file test nào khác.
  - Ghi `.bangiao/thay-doi.md`.
- **Tester:**
  - Viết lại các test ở §10.2, viết mới theo §10.5.
  - Được tạo `test/helpers/money_helpers.dart`, và được thêm nhóm test vào `test/data/prefs_repository_test.dart` và `test/design/assets_and_copy_test.dart`.
  - Không sửa `lib/`. Thấy lỗi trong `lib/` thì ghi vào `.bangiao/ket-qua-test.md`, không lách.
  - Không nới kỳ vọng nào của test cũ ngoài §10.2.

### 10.4 Tester sửa test cũ

| Test | Sửa thành |
|---|---|
| "Focus and Money show the placeholder" | Đổi thành "Focus shows the placeholder" (chỉ Focus). Thêm "Money is a real screen", chép kiểu test Timer ngay cạnh: sau khi chờ DB (`letDbFinish`) thì có tiêu đề "Money" (`findsNWidgets(2)`), có "Offline · no bank link" và "Add expense", không có placeholder |
| 8 test của `migration_test.dart` | `versions == [1, 2, 3]`. Kiểm `migrateAndValidate(db, 3)` từ v1 và từ v2. Từ v1: dữ liệu `habits`/`check_ins` còn nguyên. Từ v2: dữ liệu `fasts`/`prefs` còn nguyên (dùng `DatabaseAtV2` trong `schema_v2.dart`). DB mới tạo có đủ 5 bảng và `user_version` = 3. `money_entries` dùng được, và CHECK chặn `amount_minor = 0` |

### 10.5 Tester viết mới
Theo `test/` hiện có. Widget test dùng `pumpSteadyApp` (`test_app.dart`); `FakeNow`, `evening()`, `dbAction`, `breakWrites` (`widget_helpers.dart`); `letDbFinish`, `textPlain` (`timer_helpers.dart`).

- **Unit:**
  - `amount_input` (`test/features/amount_input_test.dart`):
    - Mọi dòng ở bảng §5.1.
    - `toMinor`: ("12.", 2) ra 1200, ("0.05", 2) ra 5.
    - `fromMinor`: (1240, 2) ra "12.40", (0, 2) ra rỗng.
    - `formatAmountInput` với `en_US`/USD: "" ra "$0", "12." ra "$12.", "12.4" ra "$12.4".
  - `money_format` (`test/core/money_format_test.dart`):
    - `en_US`/USD: `format` ra "$12.40", "$0.00", "$999,999,999.99".
    - JPY: `decimalsFor` = 0; `format(1235)` ra "¥1,235".
    - `de`/EUR: "12,40 €". Intl chèn khoảng trắng không ngắt U+00A0, nên chuẩn hoá trước khi so (dùng `plain` trong `timer_helpers.dart`).
    - `currencyForLocale`: `en_US` ra USD, `de_DE` ra EUR, `ja_JP` ra JPY, `xx` ra USD.
    - `formatMonth`.
  - `money_math` (`test/features/money_math_test.dart`):
    - `monthRange` cho 2026-10, 2028-02 (năm nhuận) và 2026-12.
    - `previousMonth` cho 2026-01-15 (ra 2025-12-01) và 2026-03-31 (ra 2026-02-01).
    - `inRange` ở hai đầu.
    - `totalOf`.
    - `totalsByCategory`: thứ tự, bằng nhau thì theo enum, không có mục 0.
    - `groupByDay` và `total`.
  - `normalizeMoneyNote`.
- **Repository** (`test/data/money_repository_test.dart`, `prefs_repository_test.dart`):
  - `add`, `update`, `delete`; id không có thì trả `false`.
  - `ArgumentError` khi số tiền 0, số tiền âm, quá `kMaxAmountMinor`, ghi chú 61 ký tự.
  - Thứ tự sắp xếp. `watchBetween` gồm cả hai đầu. `update` giữ `createdAt`.
  - `loadCurrency`: chưa có thì ghi fallback; đã có thì giữ dù fallback khác; giá trị hỏng thì ghi đè.
- **Component** (`test/ui/money_components_test.dart`):
  - `IconTile`: màu khi chọn; Semantics của ô chọn và ô hành động.
  - `Keypad`: thứ tự phím, `onKey`, phím '.' bị tắt, nhãn của phím xoá, mỗi phím tối thiểu 48.
  - `TransactionRow`: số tiền màu `ink`, tiêu đề dài cắt bằng ellipsis, số tiền lớn ở cỡ chữ 2.0 không tràn.
  - `BarChartRow`:
    - `fraction` 1 ra thanh rộng `w − w/3 − 8`; 0.5 ra một nửa số đó; 0.001 ra 4; 0 ra 0.
    - Nhãn số màu `ink`, nằm sau thanh.
    - Semantics gộp có cả nhãn danh mục và số tiền.
    - Số lớn ở cỡ chữ 2.0 không tràn.
- **Widget** (đồng hồ `evening()` = 2026-10-02 21:00; các file `test/widget/money_screen_test.dart`, `money_editor_test.dart`, `money_entries_test.dart`):
  - **Tab Money rỗng:** có "$0.00" và câu `moneyEmpty`. Không có "See all", "BY CATEGORY", "Last month".
  - **Thêm khoản chi:**
    - Bấm "Add expense": thanh tab biến mất, tiêu đề màn là "Add expense".
    - Bấm 1, 2, ., 4: hiện "$12.4". Save vẫn tắt cho tới khi chọn "Groceries".
    - Save: quay về tab và thấy tổng "$12.40", dòng "Groceries", chi tiết "9:00 PM", số tiền "−$12.40". BY CATEGORY có "Groceries" kèm "$12.40".
  - **More:** mở thêm 5 mục.
  - **Ghi chú:**
    - Ghi chú thành tiêu đề dòng; chi tiết thành "Groceries · 9:00 PM".
    - Đóng sheet mà không bấm Done thì ghi chú giữ nguyên.
  - **Chọn ngày hôm qua:** dòng nằm dưới YESTERDAY và không có giờ.
  - **Tháng trước:** khoản ngày 2026-09-15 giá $50 không vào tổng tháng, có dòng "Last month: $50.00", và có trong RECENT.
  - **BY CATEGORY:**
    - Groceries $320, Bills $210, Eating out $184 hiện theo thứ tự đó từ trên xuống (so `dy`).
    - Thanh Groceries rộng nhất.
  - **Qua nửa đêm** 2026-10-31 sang 11-01, làm theo cách các test qua nửa đêm sẵn có:
    - Tổng về "$0.00", nhãn tháng là "November".
    - "Last month: …" bằng tổng tháng 10.
    - BY CATEGORY ẩn.
  - **Expenses:** tiêu đề ngày và tổng ngày. Ví dụ hôm nay có $48.20 và $4.50 thì tổng là "−$52.70".
  - **Sửa và xoá:**
    - Sửa số tiền thì giữ `createdAt`; tiêu đề màn là "Edit expense".
    - Delete rồi Cancel: dòng còn. Delete rồi xác nhận: dòng mất.
    - Back đóng hộp thoại trước, rồi tới sheet.
  - **Ghi lỗi:** `breakWrites(..., 'money_entries')` khi Save hoặc Delete thì hiện dòng lỗi, không có dòng mới nào trong DB, giá trị đang nhập còn nguyên.
  - **Save gọi hai lần liền:** lấy `SteadyButton` rồi gọi `onPressed!()` hai lần, không `await`, giống vòng S3. Kết quả: đúng một dòng, không có dòng lỗi.
  - **Tiền tệ:**
    - Đặt `platformDispatcher.localeTestValue = Locale('de', 'DE')` trước lần mở đầu: số tiền hiện "€…".
    - Đổi lại `en_US` rồi dựng lại app (cùng DB): vẫn "€".
    - Prefs `money.currency` = `'EUR'` cũng cho ra "€".
  - **Đọc DB lỗi:** `DROP TABLE money_entries` trước lần mở đầu thì hiện `moneyLoadError`.
  - **Chưa mở tab Money:** trong cây không có `find.text('Spent this month', skipOffstage: false)`.
- **Bố cục** (`test/widget/money_layout_test.dart`): theo biên 13 ở §9, cỡ chữ 1.0 và 2.0. Riêng cỡ chữ 1.0, kiểm ràng buộc "không cần cuộn" ở cuối §7.2 bằng `getRect`.
- **Copy và icon** (`assets_and_copy_test.dart`):
  - Nhóm "money copy" kiểm từng key ở §8.
  - Nhóm "money icons" kiểm 15 hằng mới có file.
  - Tổng số SVG vẫn là 67.

---

## 11. Quy ước và file mẫu để chép

- **Dart:** `dart format`; lint theo `analysis_options.yaml`; tên file snake_case; mỗi file một widget public (widget private thì được).
- **Bảng, converter, CHECK, `// ignore: recursive_getters`:** `lib/data/database.dart`.
- **Repository và upsert:** `lib/data/habit_repository.dart`, `check_in_repository.dart`, `prefs_repository.dart`.
- **Hàm chuẩn hoá ghi chú:** `lib/features/check_in/check_in_rules.dart` (`normalizeCheckInNote`).
- **Tab mở lần đầu mới dựng:** `lib/features/timer/timer_screen.dart`.
- **Nghe stream trong State, nghe `today`, huỷ trong `dispose`:** `lib/features/timer/fasting_view.dart`. Khác ở một điểm: lỗi stream phải hiện ra, không được để `onError: (_) {}`.
- **Route toàn màn hình có hàng X:** `lib/features/timer/interval_run_screen.dart`. Push bằng `MaterialPageRoute`, như trong `interval_setup_view.dart`.
- **Vùng cuộn và vùng nút cố định:** `lib/features/check_in/check_in_screen.dart`.
- **Sheet và cờ busy:** `lib/features/streaks/habit_actions_sheet.dart`, `add_habit_sheet.dart` (cả mẫu `showDatePicker`), `lib/ui/components/steady_dialogs.dart`.
- **Chặn bấm lặp:** `lib/features/timer/fasting_view.dart` (`_start`, `_end`).
- **Component:**
  - Code mẫu: `steady_segmented_control.dart`, `steady_icon_button.dart`, `steady_stepper.dart`, `steady_chip.dart`, `steady_button.dart`, `steady_progress_bar.dart`.
  - Màu chỉ qua `SteadyColors.of`; khoảng cách và kích thước qua `SteadySpace`, `SteadyRadius`, `SteadySize`; kiểu chữ qua `SteadyText`. `moneyXl` có sẵn trong `typography.dart`.
- **Định dạng:** `lib/core/format/formatting.dart` (cache theo tag, `formatLocaleOf`, `formatClockTime`, `formatShortDate`).
- **Chữ hiển thị** chỉ đi qua `AppLocalizations`. `test/static_rules_test.dart` chặn `Text('...')` viết cứng, `DateTime.now()`, và `Color(0x` ngoài `tokens.dart`.
- **Thiết kế:**
  - `design/mockups/money/Main.dc.html`, `AddExpense.dc.html`, `Transactions.dc.html`, và phần "Spending by category" của `Report.dc.html`.
  - Bỏ qua: icon Settings, TabBar, mục BUDGETS, nút Income, segmented Expense/Income, nút Card, ô tìm kiếm, bộ lọc, dòng chuyển tiền, ô Income/Spent/Saved và "Export as CSV" của Report, câu "… no spending yet".
  - Không dùng `Envelopes.dc.html`, `Rule503020.dc.html`, `BudgetSetup.dc.html`.
  - `design/steady-ds/README.md`: các mục Màu, Chữ, Biểu tượng, và mẫu màn Money/Báo cáo. Không sửa file nào trong `design/`.
- **Test:**
  - `test/helpers/test_app.dart`, `widget_helpers.dart`, `timer_helpers.dart`.
  - Quy tắc của `dbAction`: mỗi lần ghi một `runAsync`.

---

## 12. Tiêu chí xong

- Mọi lệnh ở §2 bước 5 trả mã 0. `flutter analyze` báo "No issues found!".
- Sau Coder: các test rớt nằm trong §10.2, và `thay-doi.md` ghi đúng danh sách đó.
- Sau Tester: toàn bộ test xanh ở cả múi giờ mặc định và `TZ=America/New_York`. Số test lớn hơn 722.
- Có `drift_schemas/drift_schema_v3.json`. `test/generated_migrations/schema.dart` có `versions` = [1, 2, 3].
- `grep -rn "DateTime.now()" lib` không có kết quả. `Color(0x` chỉ xuất hiện trong `lib/core/theme/tokens.dart`.
- Không thêm package, không thêm SVG. `pubspec.yaml` không đổi.
