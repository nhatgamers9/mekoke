# Kết quả kiểm thử: GĐ3 phần 1, tab Money (theo dõi chi tiêu)

Tester, chặng 3 của /ship. Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `d88adf6` (phần Coder chưa commit). Không commit, không push, không đổi nhánh. Chỉ tạo và sửa file trong `test/` (và file này).

---

## 1. Kết luận

**XANH HẾT. Không có test nào rớt vì code sai. Không có gì phải dừng lại.**

| | Trước Tester (Coder báo, tôi chạy lại và khớp) | Sau Tester |
|---|---|---|
| `flutter test`, múi giờ mặc định (UTC) | +718 -4 (722 test; tôi chạy lại, khớp Coder) | **+1188, 0 rớt** |
| `TZ=America/New_York flutter test` | +718 -4 (722 test) | **+1188, 0 rớt** |
| `dart format --output=none --set-exit-if-changed lib test` | mã thoát 0 | mã thoát 0 |
| `flutter analyze` | No issues found! | No issues found! |

- Ràng buộc "màn nhập không cần cuộn ở 360×800, cỡ chữ 1.0" **đạt với phông thật** (`maxScrollExtent` = 0). Không nới. Xem mục 4.
- Gây lỗi cố ý trên bản sao ngoài repo: **40 đột biến, 40 bị test bắt, 0 sống sót** (mục 5).
- Tôi không sửa dòng nào trong `lib/`. Đã kiểm: không file nào ở `lib/`, `assets/`, `design/`, `drift_schemas/`, `pubspec.*` mới hơn `.bangiao/thay-doi.md`.
- Có vài quan sát ngoài đặc tả, không chặn (mục 8).

---

## 2. Test cũ đã sửa (§10.2, §10.4)

### `test/widget/shell_navigation_test.dart`
| Trước | Sau |
|---|---|
| "Focus and Money show the placeholder" (rớt) | **"Focus shows the placeholder"** (chỉ Focus) |
| (chưa có) | **"Money is a real screen"**: sau khi chờ DB có tiêu đề "Money" (`findsNWidgets(2)`), "Offline · no bank link", "Add expense", không có câu placeholder, tab hiện tại là 3 |

### `test/data/migration_test.dart` (viết lại cả file: 8 test cũ thành 22 test)
Cả 8 test trong §10.2 đã đổi sang v3. Coder báo 5 test ghim v2 (`migrateAndValidate(db, 2)`) vẫn xanh nhưng **không còn kiểm đúng điều tên chúng nói** (một DB v3 vẫn "hợp lệ" với v2). Tôi đã bỏ chúng và thay bằng bản kiểm v3 chặt, kể cả "is created straight at v2…".

- Nhóm "schema version": `schemaVersion == 3`; `GeneratedHelper.versions == [1, 2, 3]`.
- Nhóm "migration from v1 to v3": `migrateAndValidate(db, 3)`; `user_version == 3` và đúng 5 bảng; từng cột đã seed của `habits` (id, tên, ngày bắt đầu, `created_at`) và `check_ins` (ngày, mood, ghi chú) còn nguyên; ba bảng mới rỗng và ghi được; DB v1 rỗng cũng lên được.
- Nhóm "migration from v2 to v3" (dùng `DatabaseAtV2`): `migrateAndValidate(db, 3)`; `user_version == 3`; `habits`, `check_ins`, **`fasts`** (plan, mục tiêu, giờ bắt đầu, giờ kết thúc, kể cả dòng đang chạy `NULL`) và **`prefs`** còn nguyên; `money_entries` rỗng và ghi được, dữ liệu cũ vẫn còn; DB v2 rỗng; CHECK còn hiệu lực sau nâng cấp.
- Nhóm "a database created fresh": `migrateAndValidate(db, 3)`; đủ 5 bảng, `user_version == 3`, mọi bảng rỗng; CHECK `amount_minor` từ chối `0`, `-1`, `kMaxAmountMinor + 1` (cả SQL thô lẫn Drift API) và chấp nhận hai biên `1`, `kMaxAmountMinor`.

---

## 3. Test mới (§10.5)

| File | Số test | Phủ |
|---|---|---|
| `test/features/amount_input_test.dart` | 50 | Mọi dòng bảng `press` §5.1; phím sai thì `ArgumentError` (ca phải thất bại); `toMinor`, `fromMinor`, `formatAmountInput` (USD, `de`/EUR "12, €", JPY); 3 ca ngẫu nhiên hạt giống cố định, mỗi ca 3000 phím cho 0, 2, 3 chữ số thập phân: số gõ ra luôn hợp lệ và không vượt `kMaxAmountMinor` (KWD 999999999.999 đúng bằng `kMaxAmountMinor`) |
| `test/core/money_format_test.dart` | 22 | USD (`$12.40`, `$0.00`, `$999,999,999.99`, giới hạn repo `$9,999,999,999.99`), JPY, `de`/EUR "12,40 €" (chuẩn hoá U+00A0 bằng `plain`), KWD 3 chữ số, locale lạ về `en`, cache theo cặp, `currencyForLocale` (en_US/de_DE/ja_JP/xx/vi_VN), `formatMonth` |
| `test/features/money_math_test.dart` | 34 | `monthRange` (2026-10, 2028-02 nhuận, 2100-02 không nhuận, 2026-12, 12 tháng của 2026), `previousMonth` (**tháng 1**, 2026-03-31, tháng 3 năm nhuận), `inRange` hai đầu, `totalOf`, `totalsByCategory` (thứ tự, hoà theo enum, không có mục 0), `groupByDay`, `DayGroup.total`, `CategoryTotal` |
| `test/features/money_labels_test.dart` | 24 | Nhãn và icon của 12 danh mục đúng bảng §5.4, `expenseAmount` (dấu − U+2212, không gạch nối), `entryTitle`, `entryDetail` (mọi nhánh, 24 giờ, qua nửa đêm, ngày khác ngày tạo), `dayHeader`, `dateLabel` |
| `test/data/money_types_test.dart` | 11 | Tên 12 danh mục (lưu vào DB bằng `name` nên không được đổi), hằng giới hạn, `normalizeMoneyNote` (trim, xuống dòng thành dấu cách, rỗng thì null, 60/61 ký tự, 60/61 grapheme emoji) |
| `test/data/money_repository_test.dart` | 61 | `add`/`update`/`delete`; id không có thì `false`; `ArgumentError` cho số tiền 0, âm, vượt `kMaxAmountMinor`, ghi chú 61 ký tự (và không ghi gì xuống DB); **DB từ chối ghi** (trigger) cho cả ba thao tác; `update` giữ `createdAt` dù đồng hồ đã chạy; thứ tự `date DESC, createdAt DESC, id DESC`; `watchRecent`; `watchBetween` gồm hai đầu, qua năm mới, năm nhuận; stream phát lại khi dữ liệu đổi |
| `test/data/prefs_repository_test.dart` (thêm nhóm) | +21 (tổng 41) | `loadCurrency`: chưa có thì ghi fallback; đã có thì giữ dù fallback khác; 13 dạng giá trị hỏng bị ghi đè; DB đóng thì trả fallback không ném; ghi lỗi thì vẫn trả fallback |
| `test/ui/money_components_test.dart` | 44 | `IconTile` (màu chọn/không chọn, đĩa 64, Semantics của ô chọn và ô hành động, nhãn 2 dòng, cỡ chữ 2.0); `Keypad` (thứ tự phím, `onKey`, '.' hiện dấu locale nhưng gửi '.', '.' tắt, nhãn phím xoá, mỗi phím ≥ 48 và cao 56); `TransactionRow` (số tiền màu `ink`, ellipsis, số lớn ở 2.0 không tràn và không quá nửa hàng, divider, Semantics gộp); `BarChartRow` (`w−w/3−8`, nửa, 4, 0, NaN, kẹp, nhãn số ngay sau thanh, Semantics gộp, cỡ chữ 2.0) |
| `test/design/assets_and_copy_test.dart` (thêm 2 nhóm) | +9 (tổng 33) | "money copy": từng key của §8, dấu − U+2212, không có câu về thu nhập/tích trữ/hạn mức/chuyển tiền; "money icons": 15 hằng đúng tên và có file, tổng SVG vẫn 67 |
| `test/widget/money_screen_test.dart` | 43 | Tab rỗng; chưa mở tab thì không dựng gì; **không có câu SQL nào trên `money_entries` trước lần mở đầu và không còn câu nào sau khi gỡ app** (bắt log SQL của Drift); lỗi đọc DB (`DROP TABLE`) ra `moneyLoadError`; tổng tháng gồm ngày 1 và ngày cuối, ngày liền kề không vào; "Last month" (tháng trước, ẩn khi 0, **tháng 1 lấy tháng 12 năm trước**, tháng 2 nhuận, số lớn nhất); RECENT (5 khoản, ghi chú, giờ 24h, khoản khác ngày không có giờ); BY CATEGORY (thứ tự, tỉ lệ thanh, thanh tối thiểu 4, hoà theo enum, ẩn khi rỗng); **qua nửa đêm** sang tháng mới, sang năm mới, cùng tháng, đồng hồ lùi sang tháng trước, quay lại từ nền; tiền tệ (en_US, de_DE giữ € sau khi đổi vùng, en_GB, ja_JP, vi_VN, EUR/JPY có sẵn, giá trị hỏng bị ghi đè, ghi prefs lỗi vẫn mở được) |
| `test/widget/money_editor_test.dart` | 56 | Mở màn nhập (thanh tab biến mất), 7 mục + More, More mở 12 mục; bàn phím 1 2 . 4 ra `$12.4`; Save tắt cho tới khi chọn danh mục và cho mọi dạng số 0; 9 chữ số phần nguyên; Save về tab với tổng/dòng/thanh; dữ liệu lưu đúng (cent, ngày, `createdAt`); ghi chú (Done, đóng không Done, xoá, trim); ngày (lịch kết thúc hôm nay, hôm qua dưới YESTERDAY không có giờ, ngày tháng trước, nhãn đổi khi qua nửa đêm); JPY/EUR/KWD; **sửa** (điền sẵn, More tự mở, giữ id và `createdAt`, đổi cả danh mục/ngày/ghi chú, khoản ngày 2026-10-09 mở lịch không crash); **ghi lỗi** (hiện dòng lỗi, giữ giá trị, thử lại được, phím/danh mục xoá lỗi); **hai lần Save liền** (thêm, sửa, sau lỗi); hai lần bấm Date/Note chỉ mở một hộp; Semantics (số tiền là live region, nhóm "Category") |
| `test/widget/money_entries_test.dart` | 34 | Expenses (đủ mọi khoản, TODAY/YESTERDAY/SEP 30/DEC 31, 2025, tổng ngày có dấu − `−$52.70`, thứ tự, JPY, X và Back, khoản mới hiện ngay, đổi nhãn qua nửa đêm, số lớn ở 2.0, lỗi đọc, rỗng sau khi xoá hết); sheet hành động (nội dung, nút danger, Edit); **xoá** (hỏi trước, Cancel giữ dòng và sheet, xác nhận xoá và đóng sheet, **Back đóng hộp thoại trước rồi tới sheet**, bấm đúp chỉ một hộp, nút tắt khi hộp mở, dòng đã mất vẫn đóng sheet, **ghi lỗi** ra dòng lỗi mà sheet và dòng còn nguyên, thử lại sau khi DB khoẻ); **màu**: tab/màn nhập/Expenses không có `rose` hay `tide`, `rose` chỉ nằm trong nút "Delete expense" và nút Delete của hộp thoại |
| `test/widget/money_layout_test.dart` | 33 | 360×800, cỡ chữ **1.0 và 2.0**, không overflow: tab rỗng / có dòng / số lớn nhất + ghi chú 60 ký tự / đủ 12 thanh; màn nhập (mới mở, More mở, số lớn nhất, dòng lỗi); màn sửa (khoản `kMaxAmountMinor`); Expenses; sheet hành động (cả dòng lỗi); hộp xác nhận; **sheet ghi chú với bàn phím 300 px**. Ở 1.0: mọi vùng chạm (`Semantics button`, ô danh mục, phím, hàng) ≥ 48 |
| `test/widget/money_editor_fit_test.dart` | 9 | **Phông thật.** Ràng buộc không cần cuộn (mục 4) |
| `test/helpers/money_helpers.dart` | (helper) | `loadRealFonts`, `openMoney`, `openEditor`, `seedExpense`, `storedExpenses`, `pressKeys`, `pickCategory`, `tapSave`, `setDeviceLocale`, ... |

Ca **phải thất bại** có ở mọi tầng: repository từ chối số tiền 0/âm/vượt giới hạn và ghi chú 61 ký tự; CHECK của SQLite từ chối `0`, `-1`, `kMaxAmountMinor + 1`; `press` phím sai; lỗi ghi DB khi lưu, sửa, xoá; sửa khoản đã bị xoá ở nơi khác; hai lần Save liền.

Mọi ca biên §9 đã có test: 1 migration, 2 số tiền, 3 Save hai lần, 4 ghi lỗi, 5 tháng (kể cả tháng 1, năm nhuận, qua nửa đêm), 6 BY CATEGORY, 7 "Last month" ẩn, 8 chọn ngày, 9 giờ ở chi tiết, 10 nhóm theo ngày, 11 tiền tệ, 12 stream, 13 bố cục và vùng chạm, 14 màu.

---

## 4. Ràng buộc "không cần cuộn" ở 360×800, cỡ chữ 1.0 (§7.2) và phông thật

`test/widget/money_editor_fit_test.dart` nạp Figtree và Newsreader thật bằng `FontLoader` trong `setUpAll` (theo mục 5.1 của `thay-doi.md`). Mỗi file test chạy trong tiến trình riêng nên việc nạp phông không ảnh hưởng test khác; vì vậy tách thành file riêng thay vì để chung `money_layout_test.dart` (các test bố cục còn lại vẫn dùng Ahem, rộng hơn nên là phép thử tràn chặt hơn).

Số đo (probe tạm, đã xoá), 360×800, không inset hệ thống:

| Phông | `maxScrollExtent` | Vùng nhìn thấy | Nội dung |
|---|---|---|---|
| **Thật** (Figtree + Newsreader) | **0** | 392 | ≤ 392 |
| Ahem (mặc định của `flutter test`) | 24 | 392 | 416 |

Khớp với số của Coder. **Không nới ràng buộc.** Các kiểm tra (9 test):
- đối chứng: phông thật đã nạp (nhãn "Groceries" rộng < 70 và cao một dòng, thay vì Ahem 77 và hai dòng);
- `maxScrollExtent == 0` trên màn thêm;
- cả bốn khối nằm trong màn mà không cuộn, đo bằng `getRect`: số tiền, hai hàng danh mục (ô đầu và ô More), hàng Date/Note, Keypad và nút Save (đáy ≤ 800), không chồng lên nhau;
- kéo vùng cuộn không dịch chuyển (`pixels == 0`);
- vẫn không cuộn sau khi gõ 999999999.99 và chọn danh mục; màn sửa khoản Groceries có ghi chú 60 ký tự cũng không cuộn;
- có thanh trạng thái và thanh điều hướng (24/48) thì màn cuộn được, Date/Note/Save vẫn tới được, không tràn (đúng chủ đích của `SingleChildScrollView`);
- mở More (12 ô) thì cuộn thay vì tràn; cỡ chữ 2.0 thì cuộn, Save tới được, không tràn.

**Đối chứng bắt buộc:** trên bản sao ngoài repo, bỏ bước nạp phông thì test rớt đúng như Coder dự đoán: `Expected: <0> Actual: <24.0>` (và ô "Groceries" `Actual: <77.0>`). Đột biến M31 (thêm 12 px vào khoảng cách lưới danh mục) cũng làm test này rớt với phông thật.

---

## 5. Gây lỗi cố ý trên bản sao đặt ngoài repo

Bản sao: `/tmp/claude-0/-home-user-mekoke/cc7bfc32-2202-5695-aafd-72552f98ca86/scratchpad/mekoke_copy` (chép bằng `tar`, bỏ `.git`, `graphify-out`, `build`; có `flutter pub get --offline`). Quy trình cho mỗi đột biến: sửa **một chỗ** trong `lib/` của bản sao, chạy các file test liên quan, ghi lại, khôi phục. Trước đó bản sao chạy xanh nguyên vẹn (**+469** ở các file liên quan). Sau cùng `diff -rq lib` giữa bản sao và repo: **giống hệt**. Kịch bản: `scratchpad/mutate.py`, nhật ký: `scratchpad/mutation.log`.

Kết quả: **KILLED 40 / SURVIVED 0 / không có đột biến lỗi biên dịch hay không áp dụng được.**

| # | Đột biến (một chỗ trong `lib/`) | Số test rớt | Bắt bởi |
|---|---|---|---|
| M01 | bỏ `createTable(moneyEntries)` ở `from < 3` | 11 | `migration_test` |
| M02 | `schemaVersion` 3 thành 2 | 2 | `migration_test` |
| M03 | repo không chặn số tiền vượt giới hạn | 3 | `money_repository_test` |
| M04 | repo cho phép số tiền 0 | 4 | `money_repository_test` |
| M05 | `update` ghi lại `createdAt` | 2 | `money_repository_test`, `money_editor_test` |
| M06 | `previousMonth` không xử lý tháng 1 | 5 | `money_math_test`, `money_screen_test` |
| M07 | `inRange` loại ngày cuối | 12 | `money_math_test`, `money_screen_test` |
| M08 | `_save` bỏ `if (_busy) return` | 5 | `money_editor_test` (hai lần Save liền ra hai dòng) |
| M09 | `_pickDate` bỏ chốt `_busy` | 1 | `money_editor_test` |
| M10 | `_editNote` bỏ chốt `_busy` | 1 | `money_editor_test` |
| M11 | giới hạn nhập 9 thành 10 chữ số | 4 | `amount_input_test` |
| M12 | tab không nghe lại stream khi sang tháng mới | 2 | `money_screen_test` |
| M13 | luôn hiện dòng "Last month" | 4 | `money_screen_test` |
| M14 | `_delete` của sheet bỏ chốt `_busy` | 1 | `money_entries_test` (hai hộp xác nhận) |
| M15 | `BarChartRow` bỏ mức tối thiểu 4 | 2 | `money_components_test`, `money_screen_test` |
| M16 | số tiền của `TransactionRow` màu `rose` | 3 | `money_components_test`, `money_entries_test` |
| M17 | `entryDetail` hiện giờ cả khi khác ngày | 5 | `money_labels_test`, `money_screen_test` |
| M18 | `loadCurrency` nhận mọi giá trị đã lưu | 15 | `prefs_repository_test`, `money_screen_test` |
| M19 | `decimalsFor` luôn trả 2 | 7 | `money_format_test`, `money_editor_test` |
| M20 | phím '.' gửi dấu của locale | 1 | `money_components_test` |
| M21 | độ dài ghi chú đếm theo UTF-16, không theo grapheme | 2 | `money_types_test`, `money_repository_test` |
| M22 | tab Money lại là placeholder | 42 | `shell_navigation_test`, `money_screen_test` |
| M23 | màn sửa không tự mở More | 1 | `money_editor_test` |
| M24 | `update` trả `false` không bị coi là lỗi | 1 | `money_editor_test` |
| M25 | tab mở stream trước lần chọn đầu | 6 | `money_screen_test` |
| M26 | không huỷ subscription hai tháng khi `dispose` | 1 | `money_screen_test` (log SQL) |
| M27 | lịch cho chọn ngày sau hôm nay | 2 | `money_editor_test` |
| M28 | `totalsByCategory` bỏ luật hoà theo enum | 2 | `money_math_test` |
| M29 | `watchBetween` loại cả hai đầu | 6 | `money_repository_test` |
| M30 | `delete()` trả `false` thì không đóng sheet | 1 | `money_entries_test` |
| M31 | khoảng cách lưới danh mục +12 px | 3 | `money_editor_fit_test` (phông thật) |
| M32 | `formatAmountInput` mất dấu chấm cuối | 6 | `amount_input_test`, `money_editor_test` |
| M33 | mọi thanh BY CATEGORY dài bằng nhau | 2 | `money_screen_test` |
| M34 | tổng tháng này cộng cả tháng trước | 11 | `money_screen_test` |
| M35 | `dayHeader`: "hôm qua" thành hai ngày trước | 5 | `money_labels_test`, `money_entries_test` |
| M36 | `monthRange` ngày cuối luôn là 30 | 15 | `money_math_test`, `money_screen_test` |
| M37 | phím '.' không bao giờ bị tắt | 2 | `money_components_test`, `money_editor_test` |
| M38 | Save bật khi số tiền bằng 0 | 1 | `money_editor_test` |
| M39 | thứ tự repo: `createdAt` tăng dần | 1 | `money_repository_test` |
| M40 | repo không chuẩn hoá ghi chú | 6 | `money_repository_test` |

Chỉ có một đột biến "tương đương" tôi cố ý không đưa vào: bỏ `removeListener(today)` khi `dispose` (code đã có `if (!mounted) return`, nên không đổi hành vi nhìn thấy được).

---

## 6. Kết quả từng lệnh

| Lệnh | Kết quả |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | mã thoát 0 (`Formatted 116 files (0 changed)`) |
| `flutter analyze` | `No issues found!` |
| `flutter test` (UTC, múi giờ mặc định) | **+1188, 0 rớt**, mã thoát 0 |
| `TZ=America/New_York flutter test` | **+1188, 0 rớt**, mã thoát 0 |

Số test theo file (chạy riêng từng file, đều xanh): migration 22, shell_navigation 19, money_repository 61, money_types 11, prefs_repository 41, amount_input 50, money_math 34, money_labels 24, money_format 22, money_components 44, assets_and_copy 33, money_screen 43, money_editor 56, money_entries 34, money_layout 33, money_editor_fit 9.

Số test 722 thành 1188 (tăng ròng 466): 4 test rớt đã được sửa, 5 test ghim v2 đã được viết lại, phần còn lại là test mới. Danh sách 4 test rớt sau Coder đều đã được xử lý đúng §10.2/§10.4.

---

## 7. Phần rớt

**Không có.** Không có test nào đúng đặc tả mà rớt vì code sai, nên không có tên test, thông báo lỗi hay dòng nghi ngờ cần báo.

---

## 8. Quan sát cho Reviewer (ngoài đặc tả, không chặn, không phải test rớt)

1. **`TransactionRow` có hành động chạm nhưng không có cờ `button` trong Semantics.** Kế hoạch §6 và README của `TransactionRow` chỉ ghi `MergeSemantics > Material > InkWell(onTap)` nên code đúng đặc tả. Nhưng `InkWell` chỉ cho `tap`, không cho `isButton`; trong khi `StreakCard` (cũng là thẻ chạm được) tự đặt `Semantics(button: true)`. Với TalkBack, hàng khoản chi sẽ không được đọc là "nút". Test hiện chỉ khẳng định có nhãn gộp và có hành động chạm.
2. **Ô ghi chú của Money là ô một dòng, nên Flutter bỏ ký tự xuống dòng khi dán** ("Power⏎bill" thành "Powerbill", không có dấu cách) trước khi tới `normalizeMoneyNote`. Việc "xuống dòng thành dấu cách" chỉ có tác dụng ở mức repository (đã test), không có tác dụng ở giao diện. Check-in dùng ô ba dòng riêng nên không gặp chuyện này. Hậu quả nhỏ.
3. **Trạng thái "đang lưu" (nút Save mờ) không quan sát được** trong test vì DB trong bộ nhớ chạy theo microtask nên một lần `pump()` đã lưu xong và nhả `_busy`. Tôi đã kiểm bằng hành vi (gọi `onPressed!()` hai, ba lần liền chỉ ra một dòng, không có dòng lỗi), và M08 chứng minh test bắt được khi bỏ chốt. Với Delete thì quan sát được trực tiếp (hai nút tắt khi hộp thoại mở).
4. **Phép đo bố cục chỉ đạt "không cuộn" với phông thật và không có inset hệ thống** (đúng như Coder nói). Test có phần kiểm màn vẫn dùng được khi có thanh trạng thái/điều hướng (cuộn tới được mọi nút).
5. **Danh sách Expenses dùng `ListView.builder` (lười):** các hàng ở xa chỉ được dựng khi cuộn tới. Test bố cục có cuộn tới ngày cuối để dựng cả hàng ở xa.
6. **Ghi chú kỹ thuật cho người viết test sau:** (a) tôi đã gặp ca mở stream Drift (`watchAll().first`) bên trong `runAsync` rồi gọi `disposeSteadyApp` làm `db.close()` treo (tái hiện được, đổi sang đọc một lần thì hết); helper `storedExpenses` dùng `select().get()`. (b) Sau khi gỡ app phải `pump(Duration.zero)` trước `services.dispose()`. (c) `find.byType(Widget)` chỉ khớp đúng kiểu `Widget`, không khớp lớp con; bộ quét màu `rose`/`tide` dùng `find.byWidgetPredicate((_) => true)` và có ca đối chứng tìm thấy màu đỏ ở nút Delete.
7. **Không chạy `graphify update .`** (CLAUDE.md yêu cầu sau khi sửa mã) vì ràng buộc của chặng này là chỉ tạo/sửa file trong `test/`; lệnh đó ghi vào `graphify-out/`. Đồ thị hiện cũ với các file test mới.

---

## 9. Những lần test của tôi tự sai khi viết (đã sửa, ghi lại cho minh bạch)

Không lần nào do `lib/` sai. Liệt kê để Reviewer biết chỗ nào đã được siết lại:
- Bộ quét màu `rose`/`tide` lúc đầu **rỗng** (`find.byType(Widget)`), nên các test "không có rose/tide" xanh giả. Lộ ra vì ca "chỉ nằm trong nút Delete" rớt. Đã viết lại để duyệt cả cây trong phạm vi từng màn hình, thêm ca đối chứng, và bỏ một điều kiện nới lỏng (`|| w is FilledButton`) tôi đã lỡ viết. Đột biến M16 (số tiền màu `rose`) bắt được.
- Quét cả `app_en.arb` tìm "saved" bắt nhầm câu "Check-in saved." của tính năng cũ; đã giới hạn trong các key của Money.
- Đếm sai số lần xoá ("12.40" có 5 ký tự), bấm nhầm phím `1` của Keypad thay vì ô lịch, đo kích thước `Text` trong `FittedBox` bằng `getSize` (kích thước trước khi thu nhỏ), tưởng "0.00" rồi bấm `1` thì ra số dương (bảng `press` đã nói phím thứ ba sau dấu chấm bị bỏ qua), giả định `isButton` cho `TransactionRow` (xem quan sát 1), giả định quan sát được trạng thái "đang lưu" (xem quan sát 3), và để `pump()` thay vì `pump(Duration.zero)` trước `db.close()` làm treo hai lần.
- Không có kỳ vọng nào của test cũ bị nới. Ngoài §10.2 tôi không đụng test cũ nào, ngoài việc thêm nhóm vào `prefs_repository_test.dart` và `assets_and_copy_test.dart` (được phép theo §10.3).

---

## 10. File đã tạo hoặc sửa

Chỉ trong `test/` (và file này):
- Sửa: `test/data/migration_test.dart`, `test/widget/shell_navigation_test.dart`, `test/data/prefs_repository_test.dart` (thêm nhóm), `test/design/assets_and_copy_test.dart` (thêm nhóm).
- Mới: `test/helpers/money_helpers.dart`, `test/features/amount_input_test.dart`, `test/features/money_math_test.dart`, `test/features/money_labels_test.dart`, `test/core/money_format_test.dart`, `test/data/money_types_test.dart`, `test/data/money_repository_test.dart`, `test/ui/money_components_test.dart`, `test/widget/money_screen_test.dart`, `test/widget/money_editor_test.dart`, `test/widget/money_entries_test.dart`, `test/widget/money_layout_test.dart`, `test/widget/money_editor_fit_test.dart`.
- Không đụng: `lib/`, `assets/`, `design/`, `drift_schemas/`, `pubspec.*`, `test/generated_migrations/` (Coder đã sinh; tôi không sửa).
- Bản sao dùng để gây lỗi, kịch bản và nhật ký nằm ngoài repo, trong scratchpad.
