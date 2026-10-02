# Thay đổi: GĐ3 phần 1, tab Money (theo dõi chi tiêu)

Coder, chặng 2 của /ship. Làm đúng `.bangiao/ke-hoach.md` (mọi mặc định Q1–Q8 đã được người dùng "đồng ý"). Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `d88adf6`. Không commit, không push, không đổi nhánh. Không thêm package (`pubspec.yaml`, `pubspec.lock` không đổi), không thêm SVG (vẫn 67), không đụng `design/`.

Ghi chú: `git status` hiện `.bangiao/ke-hoach.md` ở trạng thái đã sửa. Đó là bản kế hoạch có phần "Câu hỏi đã trả lời" do chặng trước ghi, tôi không sửa file này.

---

## 1. Việc làm trước khi sửa DB (kế hoạch §2 bước 1–2)

- Mốc ban đầu: `flutter test` +722, 0 rớt, ở cả múi giờ mặc định và `TZ=America/New_York`. `flutter analyze` sạch.
- Chép `drift_schema_v2.json` (và v1) ra scratchpad, chạy `dart run drift_dev schema dump lib/data/database.dart drift_schemas/`, rồi `diff`: bản dump **giống hệt** bản v2 đã commit, kể cả `_meta`. Cũng giống hệt với v1. Không có gì phải dừng; làm tiếp.
- Sau khi sửa DB: `build_runner build`, `schema dump` ra `drift_schema_v3.json`, `schema generate` ra `test/generated_migrations/schema_v3.dart`. `schema.dart` có `versions = const [1, 2, 3]`. `schema_v1.dart`, `schema_v2.dart`, `drift_schema_v1.json`, `drift_schema_v2.json` không đổi một byte.

---

## 2. File đã đổi và mỗi chỗ sửa để làm gì

### Dữ liệu
| File | Việc |
|---|---|
| `lib/data/money_types.dart` (mới) | `enum MoneyCategory` (12 mục, đúng thứ tự §4.2), `kMaxAmountMinor = 999999999999`, `kMoneyNoteMaxChars = 60`, `normalizeMoneyNote` (chép `normalizeCheckInNote`: xuống dòng thành dấu cách, trim, rỗng thì `null`, quá 60 grapheme thì `ArgumentError`). |
| `lib/data/database.dart` | Thêm bảng `MoneyEntries` (`@DataClassName('MoneyEntry')`): `id`, `amountMinor` (CHECK 1..`kMaxAmountMinor`, có `// ignore: recursive_getters` như `CheckIns.mood`), `category` (`textEnum`), `note` (nullable), `date` (`LocalDateConverter`), `createdAt`. Không có cột `kind`. `schemaVersion` 2 lên 3; `onUpgrade` giữ khối `from < 2`, thêm `if (from < 3) createTable(moneyEntries)`. |
| `lib/data/database.g.dart` | Sinh lại bằng build_runner. |
| `drift_schemas/drift_schema_v3.json` (mới) | Sinh ra, giữ trong repo. |
| `test/generated_migrations/schema.dart`, `schema_v3.dart` (mới) | Sinh lại. Đây là file test duy nhất tôi chạm vào, đúng phạm vi cho phép. |
| `lib/data/money_repository.dart` (mới) | `watchAll`, `watchRecent({limit = 5})`, `watchBetween(from, to)` (so chuỗi ISO bằng `isBetweenValues`, gồm hai đầu), `add`, `update`, `delete`. Thứ tự mọi stream `date DESC, createdAt DESC, id DESC`. `add`/`update` kiểm số tiền ngoài [1, `kMaxAmountMinor`] và ghi chú quá dài, ném `ArgumentError`, luôn lưu ghi chú đã chuẩn hoá. `update` không đổi `createdAt`, trả `false` khi không có `id`. `delete` trả `false` khi không có `id`. |
| `lib/data/prefs_repository.dart` | Thêm `loadCurrency({required fallback})`: giá trị khớp `^[A-Z]{3}$` thì trả về; không có hoặc hỏng thì ghi `fallback` (lỗi ghi thì bỏ qua) rồi trả `fallback`; lỗi đọc thì trả `fallback`, không ghi; không bao giờ ném lỗi. |
| `lib/core/services.dart` | Thêm `final MoneyRepository money`. Không đổi gì khác. |

### Định dạng
| File | Việc |
|---|---|
| `lib/core/format/money_format.dart` (mới) | `MoneyFormat(localeTag, currencyCode)` có cache theo cặp (tag, code); `decimals`, `decimalSeparator`, `format`, `formatScaled`, `currencyForLocale`, `decimalsFor`, đúng §5.2. Không bao giờ thêm dấu. |
| `lib/core/format/formatting.dart` | Thêm `formatMonth(LocalDate, tag)` (`DateFormat.MMMM`, cache theo tag). |

### Logic thuần và nhãn (`lib/features/money/`)
| File | Việc |
|---|---|
| `amount_input.dart` (mới) | `AmountInput` (`empty`, `fromMinor`, `press`, `toMinor`, `==`), `kAmountMaxIntegerDigits = 9`, `formatAmountInput`. Đúng bảng `press` ở §5.1. |
| `money_math.dart` (mới) | `monthRange`, `previousMonth` (tự xử lý tháng 1), `inRange`, `totalOf`, `CategoryTotal`, `totalsByCategory`, `DayGroup`, `groupByDay`. |
| `money_labels.dart` (mới) | `categoryLabel`, `categoryIcon`, `expenseAmount`, `entryTitle`, `entryDetail`, `dayHeader`, `dateLabel`. Giờ ở chi tiết chỉ hiện khi `createdAt` rơi đúng vào ngày của khoản. |

### Component (`lib/ui/components/`)
| File | Việc |
|---|---|
| `icon_tile.dart` (mới) | `IconTile` (đĩa 64, đang chọn thì `amberSoft` + viền trong 2px `amber` + icon `amber`; `selected: null` là ô hành động). |
| `keypad.dart` (mới) | `Keypad` 4x3, phím cao 56, phím `.` hiện dấu locale nhưng gửi `'.'`, tắt được; phím xoá trong suốt có icon. |
| `transaction_row.dart` (mới) | `TransactionRow` (không có `kind`; số tiền luôn `ink`; số lớn thu nhỏ bằng `FittedBox` trong khung tối đa 50% bề rộng hàng). |
| `bar_chart_row.dart` (mới) | `BarChartRow` (thanh `amber`, rộng tối đa `w − w/3 − 8`, tối thiểu 4 khi `fraction > 0`, nhãn số ngay sau đầu thanh). |
| `steady_icon.dart` | Thêm 15 hằng icon: `lock`, `calendar`, `delete`, `receipt`, `shoppingCart`, `coffee`, `car`, `zap`, `shirt`, `heartPulse`, `gift`, `house`, `plane`, `smartphone`, `graduationCap`. Mọi file SVG đã có sẵn trong `assets/icons/`. |

### Màn hình (`lib/features/money/`, `lib/features/shell/`)
| File | Việc |
|---|---|
| `money_screen.dart` (mới) | `MoneyScreen(isActive)` mở lần đầu theo kiểu `TimerScreen` (`_opened`); `_MoneyHome` nạp tiền tệ (vùng của máy lấy từ `platformDispatcher.locale`, không qua `formatLocaleOf`), nghe `watchRecent()` và một stream `watchBetween(đầu tháng trước, cuối tháng này)`, nghe `today` (sang tháng mới thì huỷ stream hai tháng, đặt `null`, nghe khoảng mới). Lỗi stream thì hiện `moneyLoadError`. Bố cục đúng §7.1: chip "Offline · no bank link", "Spent this month", "Last month: …" (ẩn khi bằng 0), nút Add expense, BY CATEGORY (ẩn khi rỗng), RECENT + See all, danh sách 5 khoản. |
| `entry_editor_screen.dart` (mới) | Màn nhập/sửa theo §7.2: hàng X cố định, vùng cuộn (số tiền, lưới danh mục 7 mục + More, hàng Date/Note), vùng dưới cố định (Keypad, dòng lỗi, nút Save). `_save` bắt đầu bằng `if (_busy) return;`, bật `_busy` đồng bộ trước `await` đầu tiên. |
| `note_sheet.dart` (mới) | `showNoteSheet`: trả `controller.text` khi bấm Done, `null` khi đóng bằng cách khác. |
| `entries_screen.dart` (mới) | Màn "Expenses": mọi khoản, gom theo ngày, mỗi ngày có tổng. |
| `entry_actions_sheet.dart` (mới) | Sheet Edit/Delete; Delete theo mẫu `_end`: `_busy` bật trước hộp thoại, huỷ thì dừng, xác nhận thì xoá rồi đóng sheet (kết quả `false` cũng đóng), lỗi thì dòng lỗi và sheet vẫn mở. |
| `entry_row.dart` (mới) | `EntryRow` dựng `TransactionRow`. |
| `lib/features/shell/home_shell.dart` | Tab 3 thành `MoneyScreen(isActive: _index == 3)`. `PlaceholderScreen` giữ nguyên (Focus vẫn dùng). |

### Câu chữ
| File | Việc |
|---|---|
| `lib/l10n/app_en.arb` | Thêm 41 key theo bảng §8. Placeholder số tiền/giờ/nhãn khai báo `String`. `amountExpense` dùng dấu trừ U+2212. Dùng lại `tabMoney`, `close`, `delete`, `cancel`, `saveError`. |
| `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` | Sinh lại bằng `flutter gen-l10n`. |

---

## 3. Kết quả các lệnh kiểm chứng

| Lệnh | Kết quả |
|---|---|
| `flutter pub get` | OK, `pubspec.yaml`/`pubspec.lock` không đổi |
| `dart run build_runner build` | OK (wrote 145 outputs) |
| `flutter gen-l10n` | OK |
| `dart format lib test` | `Formatted 103 files (0 changed)` |
| `dart format --output=none --set-exit-if-changed lib test` | mã thoát 0 |
| `flutter analyze` | `No issues found!` |
| `flutter test` (múi giờ mặc định) | **+718, -4** (tổng 722 test, bằng mốc) |
| `TZ=America/New_York flutter test` | **+718, -4** (tổng 722 test) |
| `grep -rn "DateTime.now()" lib` | không có kết quả |
| `grep -rn "Color(0x" lib` | chỉ `lib/core/theme/tokens.dart` |
| `ls assets/icons/*.svg \| wc -l` | 67 |
| `graphify update .` | chạy xong (2108 node, 2879 cạnh); `graphify-out/` nằm trong `.gitignore` |

Kiểm màu: trong `lib/features/money/` và 4 component mới không có `tide`/`rose`; nút "Delete expense" đỏ nhờ `SteadyButtonVariant.danger`, nút Delete của hộp thoại nhờ `destructive` mặc định.

---

## 4. Test rớt: thực tế so với kế hoạch (§10.2)

Danh sách thực tế, giống hệt ở cả hai múi giờ (tên đầy đủ như runner báo, nhóm + tên):

1. `test/widget/shell_navigation_test.dart`: **Shell and tabs Focus and Money show the placeholder**. Lý do: Money không còn là placeholder.
2. `test/data/migration_test.dart`: **schema version the app database is at version 2**. Lý do: `schemaVersion` giờ là 3.
3. `test/data/migration_test.dart`: **schema version the generated helper knows both versions**. Lý do: `versions` giờ là `[1, 2, 3]`.
4. `test/data/migration_test.dart`: **a database created fresh has all four tables and starts empty**. Lý do: DB mới có 5 bảng và `user_version` = 3.

Cả 4 đều nằm trong §10.2. **Không có test nào rớt ngoài danh sách.**

Kế hoạch dự kiến "có thể đỏ cả 8" test của `migration_test.dart`, nhưng thực tế 5 test sau **vẫn xanh**, vì chúng ghim vào v2 (`migrateAndValidate(db, 2)`) và không hề chạm `schemaVersion`:
- "migration from v1 to v2 the migrated schema is exactly the v2 schema"
- "migration from v1 to v2 every habit and check-in row of v1 is kept as it was"
- "migration from v1 to v2 the two new tables are there, empty and usable"
- "migration from v1 to v2 an empty v1 database migrates too"
- "a database created fresh is created straight at v2 with the same schema as the migration"

Test cuối xanh dù DB mới tạo giờ có thêm bảng `money_entries` (`migrateAndValidate(db, 2)` cho DB "giả vờ" đang ở v2 và dường như không bắt bảng thừa ở cấu hình mặc định); nó **không còn kiểm một DB mới tạo ở v3**. Tester vẫn viết lại theo §10.4 (kiểm v3), đừng coi "xanh" là đủ.

Tôi đã tự kiểm bằng test tạm (đã xoá, xem §6) rằng `migrateAndValidate(db, 3)` xanh từ v1 và từ v2, dữ liệu `habits`/`fasts`/`prefs` còn nguyên, DB mới tạo có đúng 5 bảng và `user_version` = 3, và CHECK chặn `amount_minor = 0`.

---

## 5. Lệch khỏi kế hoạch

Không có chỗ nào phải bỏ hay đổi hành vi đã chốt. Có một chỗ **không đạt được trong môi trường test** (5.1) và vài chỗ diễn giải/làm chặt thêm (5.2–5.8) để Tester biết.

**5.1. Ràng buộc "không cần cuộn" ở 360×800, cỡ chữ 1.0 (§7.2): đúng với phông thật, không đúng với phông Ahem của `flutter test`.**
- `flutter test` không nạp phông khai báo trong `pubspec.yaml`, nên chữ dùng Ahem (mỗi ký tự rộng 1em). Với Ahem, nhãn ô danh mục ("Groceries", "Transport", "Shopping", "Eating out") xuống 2 dòng, hàng ô cao 120 thay vì 104.
- Số đo bằng test tạm, 360×800, không có inset hệ thống:

| Phông | Cỡ chữ | `maxScrollExtent` | Nội dung / vùng nhìn thấy | Hàng ô danh mục |
|---|---|---|---|---|
| Figtree + Newsreader thật (nạp bằng `FontLoader`) | 1.0 | **0** | 384 / 392 (dư 8) | 104 + 104 |
| Ahem (mặc định của test) | 1.0 | **24** | 416 / 392 (thiếu 24) | 120 + 120 |
| thật | 2.0 | 172 | cuộn được | |
| Ahem | 2.0 | 212 | cuộn được | |

- Ở cỡ chữ 1.0 với phông thật: ô danh mục đầu tại y 160–264, hàng nút Date/Note ở y 384–432, vùng nhìn thấy kết thúc ở y 452; Keypad 464–712; nút Save 724–776 (màn cao 800). Cả bốn khối đều thấy mà không cuộn.
- Tôi không đổi thiết kế để chiều Ahem: muốn thiếu 24px biến mất phải bớt đệm, bớt chiều cao ô hoặc bớt `maxLines: 2`, tức là lệch kế hoạch và lệch thiết kế, trong khi trên máy thật ràng buộc đã đạt. Nhãn 2 dòng vẫn cần ở cỡ chữ lớn.
- **Đề nghị cho Tester:** test "không cần cuộn" nạp phông thật trước khi dựng app, ví dụ trong `setUpAll`:
  ```dart
  Future<void> _load(String family, String path) async {
    final bytes = Uint8List.fromList(File(path).readAsBytesSync());
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
  // setUpAll: _load('Figtree', 'assets/fonts/Figtree-Variable.ttf');
  //           _load('Newsreader', 'assets/fonts/Newsreader-Variable.ttf');
  ```
  Kiểm bằng `ScrollableState.position.maxScrollExtent == 0` của `Scrollable` trong `EntryEditorScreen` (hoặc `getRect` của hàng Date/Note nằm trọn trong vùng cuộn). Nếu giữ Ahem thì test này sẽ đỏ; đó không phải lỗi `lib/`. Lưu ý thêm: trên máy thật có thanh trạng thái/thanh điều hướng thì vùng nhìn thấy nhỏ hơn 392 và màn sẽ cuộn; đó là chủ đích của `SingleChildScrollView`.

**5.2. `IconTile` ô hành động (`selected: null`).** Kế hoạch ghi Semantics "chỉ có `button` và `label`". Tôi thêm `onTap` (không có `selected`, không có `inMutuallyExclusiveGroup`). Lý do: Semantics đặt `excludeSemantics: true` nên loại cả semantics của `InkWell`; thiếu `onTap` thì TalkBack không kích hoạt được ô "More".

**5.3. `_pickDate` và `_editNote` của màn nhập** cũng bắt đầu bằng `if (_busy) return;` và bật `_busy` trong lúc hộp chọn ngày/sheet ghi chú đang mở (áp dụng quy tắc S3 cho mọi hàm bất đồng bộ), để bấm đúp không mở hai hộp chồng nhau. Hệ quả nhìn thấy: nút Save mờ đi trong lúc hộp đang mở; xong thì sáng lại. Hai nút Date/Note không bị tắt (`onPressed` luôn khác `null`), chỉ chặn trong hàm. `_error` không bị xoá khi đổi ngày/ghi chú (đúng kế hoạch: chỉ phím và chọn danh mục xoá lỗi).

**5.4. Màn Expenses, hàng tiêu đề nhóm ngày.** Kế hoạch chỉ ghi "tiêu đề + tổng". Để biên 13 (không tràn ở cỡ chữ 2.0, tổng ngày có thể lớn hơn một khoản) đứng vững, tổng ngày được bọc `ConstrainedBox(maxWidth: 50% hàng)` + `FittedBox(scaleDown, centerRight)` (cùng kiểu `TransactionRow`), và tiêu đề ngày `maxLines: 1` + ellipsis.

**5.5. `kMaxAmountMinor`.** Giữ đúng giá trị kế hoạch `999999999999`. Lưu ý giá trị này là 9,999,999,999.99 với USD (rộng hơn con số "999,999,999.99" trong §0/§9). Chủ đích là đủ cho 9 chữ số phần nguyên với tiền tệ 3 chữ số thập phân (KWD). Giới hạn 999,999,999.99 của USD do `AmountInput` (9 chữ số phần nguyên) chặn ở màn nhập, không phải do DB. Đã sửa chú thích trong `money_types.dart` cho khớp.

**5.6. `MoneyRepository.add` khai báo `async`** (giống `addHabit`), nên `ArgumentError` luôn đến qua `Future`, kể cả `expect(repo.add(...), throwsArgumentError)`.

**5.7. `MoneyFormat.decimals` và `decimalSeparator`** là trường (tính một lần) thay vì getter; giá trị và API giống kế hoạch.

**5.8. `EntriesScreen` nghe `watchAll()` bằng `StreamBuilder`** (giống `StreaksScreen`) thay vì tự quản `StreamSubscription`; lỗi stream hiện `moneyLoadError`. `_MoneyHome` thì tự quản subscription đúng như §7.1.

---

## 6. Tự kiểm đã làm bằng test tạm (đã xoá hết, `test/` chỉ còn thay đổi ở `generated_migrations/`)

- **Fake-async (§7.1):** mở tab Money lần đầu (có ghi prefs `money.currency`), lưu một khoản, sửa, xoá (Cancel rồi xác nhận): không treo trong vùng fake-async, dùng `letDbFinish`/`afterTapDb` như các test sẵn có. Không phải bỏ lần ghi prefs.
- **Luồng:** Save tắt tới khi chọn danh mục; bấm 1 2 . 4 ra "$12.4"; sau Save thấy "$12.40", dòng "Groceries", "9:00 PM", "−$12.40" và BY CATEGORY; Edit giữ giờ; Delete đúng hai nhánh; `onPressed!()` gọi hai lần liền chỉ ra một dòng, không có dòng lỗi; `breakWrites` ở Save và Delete cho dòng lỗi, giá trị còn nguyên, màn/sheet không đóng; `de_DE` ra "€0.00" và ghi `EUR`; `DROP TABLE` ra `moneyLoadError`; qua nửa đêm 10-31 sang 11-01 ra "November", "Last month: $45.00", BY CATEGORY ẩn; thứ tự BY CATEGORY 320 > 210 > 184; Expenses ra TODAY / YESTERDAY / "DEC 31, 2025" và tổng ngày; JPY tắt phím '.' và ra "¥1,235"; ngày hôm qua ra "Yesterday", không có giờ; ghi chú ra tiêu đề, đóng sheet không bấm Done thì ghi chú giữ nguyên; giờ 24h ra "Transport · 21:00"; sửa khoản có ngày 2026-10-09 (sau "hôm nay" 10-02) rồi mở `showDatePicker` không crash.
- **Bố cục, 360×800, cỡ chữ 1.0 và 2.0:** không overflow ở tab Money rỗng, tab có đủ 12 danh mục với số tiền lớn nhất và ghi chú 60 ký tự, Expenses, sheet hành động, màn nhập với 999,999,999.99, màn nhập đã mở More (12 ô), sheet ghi chú với bàn phím 300px. Mọi ô danh mục và phím Keypad tối thiểu 48x48.
- **Thuần:** `press` đủ các dòng bảng §5.1, `fromMinor`, `toMinor`, `formatAmountInput` (kể cả "12, €" với `de`/EUR), `MoneyFormat` (USD, JPY, EUR, KWD 3 chữ số), `currencyForLocale` (`en_US` USD, `de_DE` EUR, `ja_JP` JPY, `xx` USD, `vi_VN` VND), `formatMonth`, `monthRange` (2026-10, 2028-02, 2026-12), `previousMonth` (tháng 1), `BarChartRow` (rộng `w − w/3 − 8`, nửa, 4, 0, NaN, kẹp).
- **Dữ liệu:** migration v1 lên v3 và v2 lên v3 (`migrateAndValidate(db, 3)`), DB mới v3, CHECK chặn 0; repository (thứ tự, `watchBetween` hai đầu, `update` giữ `createdAt`, id không có trả `false`, `ArgumentError` cho 0, âm, vượt `kMaxAmountMinor`, ghi chú 61 ký tự); `loadCurrency` (chưa có thì ghi, đã có thì giữ, hỏng thì ghi đè, DB đóng thì trả fallback không ném).

---

## 7. Chỗ Tester nên soi kỹ

1. **Test "không cần cuộn" và phông Ahem** (mục 5.1). Số đo, cách nạp phông và cách kiểm đã ghi ở trên.
2. **Dấu và khoảng trắng của Intl:** `de`/EUR cho "12,40 €" với U+00A0; giờ 12h có U+202F. Dùng `plain`/`textPlain`.
3. **Tiền tệ trong UI dùng `formatLocaleOf`:** máy `de_DE` mà app chỉ có `en` nên số hiện kiểu en ("€12.40"), chỉ ký hiệu đổi. Dạng "12,40 €" chỉ có ở mức `MoneyFormat('de', 'EUR')`. Tiền tệ lấy từ `platformDispatcher.locale` (không qua `formatLocaleOf`); cần `localeTestValue` đặt **trước** lần mở tab đầu. Đổi locale về sau không đổi tiền tệ (đã lưu).
4. **Save bấm hai lần:** `_busy` bật đồng bộ trước `await` đầu tiên của `_save`. Nên thử cả `add` và `update`, và sau khi `breakWrites` (lỗi rồi bấm lại được).
5. **`update` trả `false`:** xoá dòng trong DB khi màn Edit đang mở rồi Save phải ra dòng lỗi `saveError`, màn không đóng (nhánh `StateError` trong `_save`). Nhánh này tôi chưa có test riêng.
6. **Xoá:** sau khi xác nhận mà `delete` trả `false` (dòng đã mất) vẫn đóng sheet. `finally` đặt `_busy = false` ngay cả khi sheet đang đóng (modal route chặn chạm lúc đóng). Back đóng hộp thoại trước, rồi tới sheet.
7. **Qua nửa đêm:** `_MoneyHome` chỉ nghe lại stream khi **tháng** đổi; cùng tháng chỉ `setState`. Kiểm cả trường hợp đồng hồ lùi sang tháng trước.
8. **Giờ ở dòng chi tiết:** chỉ khi `LocalDate.fromDateTime(createdAt) == date`. Khoản sửa sang ngày khác không có giờ, ghi chú còn thì chi tiết là nhãn danh mục. `createdAt` Drift chỉ lưu tới giây.
9. **`IconTile`:** ô More không có `selected` nhưng có `onTap` (mục 5.2). Ô chọn có `selected` và `inMutuallyExclusiveGroup`.
10. **`TransactionRow` và `BarChartRow` chống tràn:** số tiền tối đa 50% bề rộng hàng; thanh dài nhất đúng `maxBar`; ở cỡ chữ 2.0 nhãn số thu nhỏ bằng `FittedBox`. Bề rộng thanh đo trong khung BY CATEGORY (bề rộng trong = màn − 40 − 32).
11. **Stream:** trước khi mở tab Money lần đầu không có stream Money nào (`_opened`); `dispose` huỷ cả hai subscription và gỡ listener `today`.
12. **Bảng `money_entries`:** lưu `category` bằng `name` enum; `date` là chuỗi ISO nên `watchBetween` so chuỗi. CHECK `amount_minor BETWEEN 1 AND 999999999999` có trong `schema_v3.dart`.
13. **Phím `.`:** nhãn Semantics là dấu thập phân của locale (không phải chữ "."), phím xoá có nhãn "Delete last digit". Tiền tệ 0 chữ số thập phân (JPY) thì phím '.' `Opacity 0.4`, `enabled: false`.
14. **Biên 14 (màu):** không có `tide` ở tab Money, `rose` chỉ ở hai nút Delete.
