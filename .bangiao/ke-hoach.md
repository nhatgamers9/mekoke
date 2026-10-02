# Kế hoạch: vòng sửa tiếp, tiền tệ theo vùng (BG ra EUR, ZW ra USD)

Yêu cầu (/ship): "sửa tiếp". Phạm vi là đúng 2 việc "Cần sửa" trong bản đánh giá vòng trước, kèm test.
- Mọi đường dẫn tương đối tính từ `/home/user/mekoke/`. Viết tắt `SP` = `/tmp/claude-0/-home-user-mekoke/cc7bfc32-2202-5695-aafd-72552f98ca86/scratchpad`.
- Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `267a46a`. Thay đổi của vòng trước chưa commit (3 file `lib/`, 3 file `test/`).
- Không commit, không push, không tạo PR, không đổi nhánh.
- Không có câu hỏi bỏ ngỏ. Panama giữ `PAB`, vì người dùng không yêu cầu đổi.

---

## 0. Phạm vi

**Làm:**
1. Bảng `kRegionCurrency` phải cho `BG` ra `EUR` và `ZW` ra `USD`. Sửa bằng cách thêm ghi đè vào script rồi sinh lại file.
2. Script tự đối chiếu bảng với `DEF_CURRENCY_CODE` của intl 0.20.3.
3. Sửa chú thích đầu file `region_currency.dart`.
4. Sửa test cho khớp.

**Không làm:**
- Không sửa tay `lib/core/format/region_currency.dart`.
- Không sửa `lib/core/format/money_format.dart`, `lib/ui/components/transaction_row.dart`, hay bất kỳ file `lib/` nào khác.
- Không đổi phiên bản Babel, không đổi nguồn dữ liệu (giữ Babel 2.18.0 / CLDR 47).
- Không đổi quy tắc chọn ở vùng nhiều tiền tệ. Không thêm ghi đè nào khác (PA giữ `PAB`), trừ khi §1.3 bắt buộc.
- Không sửa `pubspec.*`, `test/widget/money_screen_test.dart`, `test/ui/money_components_test.dart`.

---

## 1. Coder: script `SP/gen_region_currency.py` (ngoài repo, không commit)

Chạy bằng `SP/ship-run5/bvenv/bin/python SP/gen_region_currency.py`. Script chỉ được ghi đúng một file trong repo: `lib/core/format/region_currency.dart`.

**Trước khi sửa:** chép file hiện tại sang `SP/region_currency.before.dart` để so sánh ở §1.5.

### 1.1 Ghi đè
Thêm hằng sau ở gần đầu file (cạnh `DATE`):
```python
OVERRIDES: dict[str, tuple[str, str]] = {
    'BG': ('EUR', 'Bulgaria dùng EUR từ 2026-01-01; CLDR 47 chưa có, intl 0.20.3 (CLDR 48) đã có.'),
    'ZW': ('USD', 'phần lớn giao dịch hằng ngày ở Zimbabwe bằng USD; ZWG không neo với USD và đã mất giá mạnh từ 2024.'),
}
```
Áp ghi đè **sau** vòng lặp chọn, theo các bước:
1. Lưu `before = dict(table)`.
2. Với mỗi `R` trong `OVERRIDES`, `assert`:
   - `R in table`;
   - mã ghi đè khớp `^[A-Z]{3}$`, khác `XXX`, và `get_currency_precision(mã) <= 3`;
   - `table[R] != mã`. Nếu bằng nhau thì ghi đè đã thừa: script phải dừng với thông báo "ghi đè thừa: R".
3. Gán `table[R] = mã`.

Danh sách 7 vùng nhiều ứng viên (`multi`) vẫn in mã do quy tắc chọn ra, như cũ. Ghi đè được in riêng ở §1.4.

### 1.2 Thứ tự `from` (để chú thích ở §2 nói đúng sự thật)
- Với mỗi vùng trong `multi`, lấy thêm `get_territory_currencies(R, DATE, tender=True, non_tender=False, include_details=True)`, giữ lại đúng các mã có trong `cands`.
- `assert` rằng ngày `from` không giảm theo thứ tự Babel trả về. `from` là `None` thì coi là sớm nhất.
- Khi in vùng nhiều ứng viên, in kèm `from` của từng mã.
- Không đổi logic chọn.

### 1.3 Đối chiếu với intl 0.20.3
- Đặt `INTL_SYMBOLS = '/root/.pub-cache/hosted/pub.dev/intl-0.20.3/lib/number_symbols_data.dart'`.
- `def read_intl_currencies(path: str) -> tuple[str, dict[str, str]]`:
  - đọc số CLDR bằng regex `File generated from CLDR ver\. (\d+)`. `assert` tìm thấy số này;
  - duyệt từng dòng:
    - dòng khớp `^  "([A-Za-z0-9_]+)": new NumberSymbols\(` mở một locale mới;
    - dòng khớp `DEF_CURRENCY_CODE: '([A-Z]{3})'` gán mã cho locale đang mở;
  - `assert` mọi locale đều có mã. Số locale phải là 119.
- `def intl_region(locale: str) -> tuple[str | None, str]` trả về `(vùng, cách lấy)`:
  1. `parts = locale.split('_')`, `rest = parts[1:]`. Nếu `rest[0]` gồm đúng 4 chữ cái (script) thì bỏ phần đó.
  2. Nếu còn `rest`:
     - `rest[0]` khớp `^[A-Z]{2}$`: trả `(rest[0], 'vùng')`;
     - không khớp (ví dụ `419`): trả `(None, 'vùng số')`.
  3. Nếu không còn `rest` (chỉ có ngôn ngữ, hoặc ngôn ngữ + script như `sr_Latn`):
     - `ls = get_global('likely_subtags')`;
     - `lang = get_global('language_aliases').get(parts[0], parts[0])`. Bước này để `in`, `iw`, `tl` ra `id`, `he`, `fil`;
     - `hit = ls.get(locale) or ls.get(lang)`;
     - có `hit` thì trả `(babel.core.parse_locale(hit)[1], 'likely')`, không có thì trả `(None, 'không rõ')`.
- Với mỗi locale có vùng `R` khác `None`, so mã intl với `before.get(R)` và với `table.get(R)`. `R` không có trong bảng cũng tính là lệch.
- Script **không dừng** vì lệch, chỉ in ra (xem §1.4).

**Kết quả mong đợi** (bản đánh giá đã tự đo):
- trước ghi đè, lệch đúng một locale: `bg` (BG: bảng BGN, intl EUR);
- sau ghi đè: 0 lệch;
- bỏ qua vì vùng số: `es_419`;
- không rõ vùng: 0 locale.

**Nếu kết quả khác mong đợi**, xử lý từng chỗ lệch còn lại sau ghi đè như sau, và ghi rõ vào `thay-doi.md`:
- **(A) Thêm vào `OVERRIDES`, theo giá trị của intl**, khi mã của intl là tiền đang lưu hành thật ở `R` vào ngày 2026-10-02. Chỉ cần một trong hai điều kiện:
  - mã đó có trong danh sách ứng viên Babel của `R`;
  - hoặc có một lần đổi tiền nêu được tên và ngày hiệu lực, không muộn hơn 2026-10-02, mà CLDR 47 chưa có (giống BG).

  Lý do ghi một dòng trong `OVERRIDES`, rồi sinh lại.
- **(B) Không ghi đè, chỉ giải thích**, khi lệch là vì locale chỉ có ngôn ngữ, còn intl gán tiền của một vùng khác với vùng mà `likely_subtags` trả về. Khi đó bảng vẫn đúng cho `R`.
- **(C) Locale ra `'không rõ'`, hoặc không xếp được vào (A) hay (B)**: không ghi đè. Ghi vào mục "Lệch chưa xử lý" của `thay-doi.md` để Reviewer quyết.

### 1.4 Phần in ra
Giữ mọi dòng in cũ, thêm các phần sau:
- dòng phiên bản: `Babel 2.18.0, CLDR 47; intl 0.20.3, CLDR <số đọc được>`;
- `Ghi đè (n):`, mỗi dòng một vùng: `R: <before[R]> -> <mã> (<lý do>)`;
- vùng nhiều ứng viên, kèm `from` (§1.2);
- `Đối chiếu intl: <số locale> locale`, rồi bốn danh sách:
  - "Lệch trước ghi đè", mỗi dòng: `locale (R, cách lấy): bảng X, intl Y`;
  - "Lệch còn lại sau ghi đè";
  - "Bỏ qua vì vùng số";
  - "Không rõ vùng";
- phần "Tra bảng" có thêm `BG` và `ZW`.

### 1.5 Sinh lại và so sánh
1. Thứ tự trong script: chọn, rồi ghi đè (§1.1), rồi assert `from` (§1.2), rồi đối chiếu intl (§1.3), rồi ghi file, rồi in. Bất kỳ `assert` nào hỏng thì script dừng và không ghi file.
2. Chạy `dart format lib`.
3. Chạy `diff SP/region_currency.before.dart lib/core/format/region_currency.dart`. Kết quả chỉ được khác ở:
   - khối chú thích `///`;
   - đúng 2 dòng: `'BG': 'EUR',` và `'ZW': 'USD',`.

   Nếu §1.3 sinh thêm ghi đè thì có thêm đúng các dòng đó. Bảng vẫn 255 mục.

---

## 2. Chú thích đầu `lib/core/format/region_currency.dart` (do script sinh)

- Giữ nguyên các đoạn hiện có về: file do script sinh; khoá và giá trị; vùng không có tiền; mã hơn 3 chữ số thập phân.
- Sửa đoạn "Nguồn" (dòng 6–9 hiện tại) và đoạn "Vùng có nhiều tiền tệ" (dòng 11–14) thành nội dung dưới đây:
  - ngắt dòng không quá 80 cột như hiện tại;
  - số CLDR, phiên bản Babel và intl lấy từ biến;
  - danh sách gạch đầu dòng sinh từ `OVERRIDES`.
- Bỏ hẳn câu "Ngày lấy dữ liệu: 2026-10-02."

```
/// Nguồn: CLDR 47 (`supplementalData`, `currencyData`), lấy qua thư viện
/// Python Babel 2.18.0, bằng lệnh `get_territory_currencies(R,
/// date(2026, 10, 2), tender=True, non_tender=False)` cho mỗi vùng `R`.
/// 2026-10-02 chỉ là ngày truy vấn truyền cho Babel, không phải ngày cập nhật
/// dữ liệu. CLDR 47 cũ hơn CLDR 48 mà intl 0.20.3 của app dùng; script đối
/// chiếu bảng với `DEF_CURRENCY_CODE` của từng locale intl theo vùng của
/// locale đó.
///
/// Ghi đè sau bước chọn (thắng dữ liệu CLDR):
/// - `BG` ra `EUR`: Bulgaria dùng EUR từ 2026-01-01; CLDR 47 chưa có, intl
///   0.20.3 (CLDR 48) đã có.
/// - `ZW` ra `USD`: phần lớn giao dịch hằng ngày ở Zimbabwe bằng USD; ZWG
///   không neo với USD và đã mất giá mạnh từ 2024.
///
/// Vùng có nhiều tiền tệ: bỏ mã không phải ISO 4217 ba chữ cái và `XXX`; nếu
/// đúng một mã bắt đầu bằng mã vùng (tiền do chính vùng đó phát hành, ví dụ
/// `BT` ra `BTN`) thì lấy mã đó; không thì lấy mã có ngày bắt đầu lưu hành
/// (`from`) sớm nhất, vì Babel trả ứng viên theo thứ tự `from` (nếu có từ hai
/// mã bắt đầu bằng mã vùng thì cũng lấy mã có `from` sớm nhất trong số đó).
```

- File bị quét bởi `test/static_rules_test.dart`. Không được có `DateTime.now()`, `Color(0x`, `Text('`.

---

## 3. Tester: `test/core/money_format_test.dart` (file duy nhất được sửa)

1. Map `cases` của nhóm `the region of the phone wins over its language`:
   - thêm `'bg_BG': 'EUR',` ngay sau `'en_GB': 'GBP',` (dòng 154), trong phần "Giữ nguyên như trước khi có bảng theo vùng".
2. Nhóm `a region with several currencies gets its own`:
   - dòng 200: `'en_ZW': 'USD',`;
   - dòng 212: `expect(MoneyFormat.currencyForLocale('en-ZW'), 'USD');`;
   - viết lại chú thích nhóm (dòng 189–192), giữ ý cũ và sửa cho đúng:
     - LS, NA: mã tự phát hành không phải mã đầu tiên Babel trả về;
     - PS: không mã nào bắt đầu bằng mã vùng, nên lấy mã có `from` sớm nhất (ILS, không phải JOD);
     - ZW: bị ghi đè ra USD, xem chú thích của `kRegionCurrency`;
   - chú thích dòng 210: đổi vế `en_ZW: tiền Zimbabwe` thành `en-ZW: ZW bị ghi đè ra USD, nhận cả "-"`.
3. Test `has the entries the plan names` (dòng 330–343): thêm `expect(kRegionCurrency['BG'], 'EUR');` và `expect(kRegionCurrency['ZW'], 'USD');`.

   Lý do: xoá hẳn dòng BG hoặc ZW thì `bg_BG` và `en_ZW` vẫn ra EUR, USD nhờ intl. Chỉ hai dòng này bắt được lỗi đó.
4. Nếu `thay-doi.md` ghi thêm ghi đè ngoài BG, ZW, thì với mỗi vùng `R` đó:
   - thêm một ca `<ngôn ngữ của locale intl>_<R>` vào `cases`;
   - thêm một dòng `expect(kRegionCurrency[R], …)` vào test ở bước 3.
5. Không nới kỳ vọng nào khác. Không sửa `lib/`. Thấy lỗi trong `lib/` thì ghi vào `ket-qua-test.md`, không lách.

**Đột biến phải bị bắt.** Làm trên bản sao ngoài repo, ví dụ `SP/mut/`, giống vòng trước. Sửa thẳng file Dart trên bản sao. Mỗi đột biến phải làm ít nhất một test rớt:

| Đột biến | Sửa trên bản sao | Test phải bắt |
|---|---|---|
| (f) bỏ ghi đè BG | `'BG': 'EUR'` thành `'BGN'` | `bg_BG gives EUR`, `has the entries…` |
| (g) bỏ ghi đè ZW | `'ZW': 'USD'` thành `'ZWG'` | `en_ZW gives USD`, ca `en-ZW`, `has the entries…` |
| (h) xoá hẳn dòng BG | xoá `'BG': …` | `has the entries…` |
| (i) xoá hẳn dòng ZW | xoá `'ZW': …` | `has the entries…` |

---

## 4. Thứ tự và lệnh kiểm chứng

Mọi lệnh chạy với `export PATH="/opt/flutter/bin:$PATH"` trong `/home/user/mekoke`.

**Coder:**
1. Chạy `flutter test` để xác nhận mốc **+1243, 0 rớt**.
2. Làm §1, §2. Chạy script, rồi `dart format lib`, rồi `diff` như §1.5.
3. Chạy `flutter analyze`, rồi `flutter test`. Kết quả mong đợi là **đúng 2 test rớt**: `en_ZW gives ZWG` và `a language that has its own region does not leak in`. Đây là kỳ vọng cũ mà Tester sẽ sửa.
   - Coder không sửa test.
   - Nếu có test khác rớt thì sửa script (§1), không sửa test.
4. Ghi `.bangiao/thay-doi.md`, gồm:
   - toàn văn phần in ra của script;
   - kết quả `diff` ở §1.5;
   - cách xử lý từng chỗ lệch với intl, theo (A), (B) hoặc (C) ở §1.3;
   - danh sách `OVERRIDES` cuối cùng;
   - tên 2 test rớt ở bước 3;
   - mọi chỗ lệch so với kế hoạch, kèm lý do.

**Tester:** làm §3, ghi `.bangiao/ket-qua-test.md`. Trong đó có bảng đột biến (f)–(i), và danh sách các ca phải giữ nguyên: `en_US`, `de_DE`, `ja_JP`, `vi_VN`, `en_GB`, `bg_BG`, `xx`, `xx_YY`.

**Lệnh chạy sau Tester:**
```
export PATH="/opt/flutter/bin:$PATH"; cd /home/user/mekoke
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
TZ=America/New_York flutter test
git status --short
graphify update .
```

---

## 5. Quy ước và file mẫu
- Script sinh bảng: bám cách viết hiện có trong `SP/gen_region_currency.py`. Dùng regex `re.fullmatch`, in bằng `print` tiếng Việt.
- Chú thích Dart: tiếng Việt, `///`, ngắt dòng không quá 80 cột, như `lib/core/format/region_currency.dart` và `lib/core/format/money_format.dart`.
- Test bảng ca theo map `cases` và `forEach`: chép mẫu `test/core/money_format_test.dart` dòng 147–187.
- Bản sao để gây lỗi cố ý: làm như `SP/mut/` của vòng trước (xem mục 2 của `SP/ship-run6/ket-qua-test.md`).

---

## 6. Tiêu chí xong
- Trong `lib/core/format/region_currency.dart`:
  - `'BG': 'EUR'`, `'ZW': 'USD'`, `'PA': 'PAB'`;
  - 255 mục; so với bản trước chỉ khác chú thích và các dòng ghi đè (§1.5);
  - chú thích đúng §2, không còn câu "Ngày lấy dữ liệu".
- Script chạy không lỗi:
  - "Lệch còn lại sau ghi đè" rỗng, hoặc mỗi mục đều được giải thích theo (B) hoặc (C) trong `thay-doi.md`;
  - script vẫn nằm ngoài repo.
- `bg_BG` ra EUR; `en_ZW`, `en-ZW` ra USD. Các ca giữ nguyên ở §4 không đổi.
- `flutter analyze` báo "No issues found!". Lệnh format thoát với mã 0.
- `flutter test` ra **+1244, 0 rớt** ở cả múi giờ mặc định và `TZ=America/New_York`. 1243 cộng 1 ca `bg_BG`, cộng thêm mỗi ca của bước 3.4 nếu có.
- Bốn đột biến (f), (g), (h), (i) đều bị bắt.
- `git status --short` chỉ có 3 file `lib/` và 3 file `test/` của vòng trước, cùng `.bangiao/`. Vòng này chỉ đổi `lib/core/format/region_currency.dart` và `test/core/money_format_test.dart`. `pubspec.*` không đổi.
