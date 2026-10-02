# Thay đổi: vòng sửa tiếp, tiền tệ theo vùng (BG ra EUR, ZW ra USD)

Viết tắt: `SP` = `/tmp/claude-0/-home-user-mekoke/cc7bfc32-2202-5695-aafd-72552f98ca86/scratchpad`.
Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `267a46a`. Không commit, không push, không đổi nhánh, không tạo PR.

## 1. Tóm tắt

- Chỉ sửa script `SP/gen_region_currency.py` (ngoài repo), rồi sinh lại `lib/core/format/region_currency.dart`. Không sửa tay file Dart nào, không sửa test.
- Bảng giờ cho `BG` ra `EUR` và `ZW` ra `USD`. `PA` vẫn `PAB`. Bảng vẫn 255 mục.
- Đối chiếu với intl 0.20.3 (CLDR 48): trước ghi đè lệch đúng 1 locale (`bg`), sau ghi đè 0 lệch. Không có ca (A), (B), (C) nào ngoài BG, ZW.
- `flutter test` rớt đúng 2 test cũ như kế hoạch dự kiến, ở cả hai múi giờ. Việc sửa 2 test này thuộc về Tester.

## 2. File đã thay đổi

| File | Trong repo | Sửa để làm gì |
|---|---|---|
| `lib/core/format/region_currency.dart` | có (chưa theo dõi, do script sinh) | Chú thích đầu file viết lại theo §2 kế hoạch. 2 mục đổi: `'BG': 'EUR'`, `'ZW': 'USD'`. |
| `SP/gen_region_currency.py` | không | Thêm `OVERRIDES`, kiểm tra thứ tự `from`, đối chiếu intl, chú thích sinh theo biến, phần in thêm. Chi tiết ở §3. |

Không đụng: `lib/core/format/money_format.dart`, `lib/ui/components/transaction_row.dart`, mọi file `lib/` khác, mọi file `test/`, `pubspec.*`. Hai file `.bangiao/` còn lại không phải việc của vòng này (xem mục "Chỗ lệch so với kế hoạch").

Đã chép bản cũ của `region_currency.dart` sang `SP/region_currency.before.dart` trước khi sinh lại (277 dòng). Bản cũ của script nằm ở `SP/gen_region_currency.before.py`.

## 3. Sửa script `SP/gen_region_currency.py`

Thứ tự trong script: chọn, ghi đè, assert `from`, đối chiếu intl, dựng chú thích, ghi file, in. Mọi `assert` nằm trước bước ghi file. Đã thử thêm một ghi đè thừa (`US`: `USD`) vào bản sao: script dừng với `AssertionError: ghi đè thừa: US` và không ghi file.

- `OVERRIDES` (cạnh `DATE`): đúng nguyên văn kế hoạch §1.1. Áp sau vòng chọn, kèm các assert: `R in table`; mã khớp `[A-Z]{3}`, khác `XXX`, `get_currency_precision <= 3`; `table[R] != mã` (nếu bằng thì `ghi đè thừa: R`). Lưu `before = dict(table)` trước khi áp.
- Thứ tự `from` (§1.2): với 7 vùng `multi`, lấy `get_territory_currencies(..., include_details=True)`, giữ mã có trong `cands`, assert danh sách mã trùng thứ tự `cands` và ngày `from` không giảm (`None` coi là sớm nhất). Logic chọn không đổi.
- Đối chiếu intl (§1.3): `INTL_SYMBOLS`, `read_intl_currencies`, `intl_region` viết đúng như kế hoạch (119 locale, số CLDR đọc bằng regex). Không dừng vì lệch, chỉ in. Số phiên bản intl (`0.20.3`) lấy bằng regex từ đường dẫn `INTL_SYMBOLS`.
- Chú thích (§2): số CLDR của Babel, phiên bản Babel, số CLDR và phiên bản intl lấy từ biến. Danh sách gạch đầu dòng sinh từ `OVERRIDES` bằng `textwrap.fill(width=79, ...)`. Đã so khối `///` dòng 6-24 của file sinh ra với khối mẫu ở `ke-hoach.md` dòng 127-145: khớp từng byte. Dòng `///` dài nhất là 79 cột. Câu "Ngày lấy dữ liệu: 2026-10-02." đã bỏ.
- Phần in thêm (§1.4): xem output ở §4. Dòng phiên bản cũ `Babel 2.18.0, CLDR 47` được kéo dài thành `Babel 2.18.0, CLDR 47; intl 0.20.3, CLDR 48` (một dòng, giữ nguyên phần đầu). Dòng vùng nhiều ứng viên giữ nguyên phần đầu `R: [cands] -> chosen` rồi thêm `(from: ...)`. Biến `cldr_note` không còn dùng nên đã bỏ, các biến khác để nguyên.

## 4. Output của script (toàn văn)

Chạy bằng `SP/ship-run5/bvenv/bin/python SP/gen_region_currency.py`. Bản lưu: `SP/ship-run7/gen_output_run7.txt`.

```
Babel 2.18.0, CLDR 47; intl 0.20.3, CLDR 48
Ngày: 2026-10-02
Số vùng xét: 266
Số mục của bảng: 255
Vùng bị bỏ vì không có ứng viên (11): AQ, BU, CP, CS, DD, SU, TP, YD, YU, ZR, ZZ
Vùng có từ 2 ứng viên trở lên (7):
  BT: ['INR', 'BTN'] -> BTN (from: INR 1907-01-01, BTN 1974-04-16)
  HT: ['HTG', 'USD'] -> HTG (from: HTG 1872-08-26, USD 1915-01-01)
  LS: ['ZAR', 'LSL'] -> LSL (from: ZAR 1961-02-14, LSL 1980-01-22)
  NA: ['ZAR', 'NAD'] -> NAD (from: ZAR 1961-02-14, NAD 1993-01-01)
  PA: ['PAB', 'USD'] -> PAB (from: PAB 1903-11-04, USD 1903-11-18)
  PS: ['ILS', 'JOD'] -> ILS (from: ILS 1985-09-04, JOD 1996-02-12)
  ZW: ['USD', 'ZWG'] -> ZWG (from: USD 2009-04-12, ZWG 2024-06-25)
Mã bị bỏ vì độ chính xác > 3 (0):
Ghi đè (2):
  BG: BGN -> EUR (Bulgaria dùng EUR từ 2026-01-01; CLDR 47 chưa có, intl 0.20.3 (CLDR 48) đã có.)
  ZW: ZWG -> USD (phần lớn giao dịch hằng ngày ở Zimbabwe bằng USD; ZWG không neo với USD và đã mất giá mạnh từ 2024.)
Đối chiếu intl: 119 locale
Lệch trước ghi đè (1):
  bg (BG, likely): bảng BGN, intl EUR
Lệch còn lại sau ghi đè (0):
Bỏ qua vì vùng số (1): es_419
Không rõ vùng (0): 
Tra bảng:
  AR: ARS
  CO: COP
  SA: SAR
  PH: PHP
  VN: VND
  MA: MAD
  KZ: KZT
  TW: TWD
  US: USD
  DE: EUR
  JP: JPY
  GB: GBP
  BG: EUR
  ZW: USD
```

Đối chiếu với kết quả mong đợi của kế hoạch §1.3:

| Mục | Mong đợi | Thực tế |
|---|---|---|
| Lệch trước ghi đè | đúng 1 (`bg`: BGN và EUR) | đúng 1: `bg (BG, likely)` |
| Lệch còn lại sau ghi đè | 0 | 0 |
| Bỏ qua vì vùng số | `es_419` | `es_419` |
| Không rõ vùng | 0 | 0 |

Ghi chú: trong 7 vùng nhiều ứng viên, dòng `ZW` vẫn in `-> ZWG` vì đó là mã do quy tắc chọn ra, đúng như kế hoạch §1.1 (ghi đè được in riêng ở mục "Ghi đè").

## 5. Cách xử lý chỗ lệch với intl (quy tắc A/B/C)

- `bg` (BG): lệch trước ghi đè. Xử lý bằng ghi đè trong `OVERRIDES` (`BG` ra `EUR`), đúng chỗ kế hoạch đã chỉ định. Đây là trường hợp thuộc (A) vì có một lần đổi tiền nêu được tên và ngày hiệu lực (Bulgaria dùng EUR từ 2026-01-01) mà CLDR 47 chưa có.
- `ZW`: không lệch với intl (intl không có locale `en_ZW`). Ghi đè theo yêu cầu riêng của /ship, không phải kết quả của bước đối chiếu.
- Lệch còn lại sau ghi đè: không có, nên không có ca (A) thêm, (B), hay (C). Mục "Lệch chưa xử lý": không có.

`OVERRIDES` cuối cùng (2 mục, không thêm ghi đè nào khác):

| Vùng | Bảng cũ | Mã ghi đè | Lý do |
|---|---|---|---|
| `BG` | `BGN` | `EUR` | Bulgaria dùng EUR từ 2026-01-01; CLDR 47 chưa có, intl 0.20.3 (CLDR 48) đã có. |
| `ZW` | `ZWG` | `USD` | phần lớn giao dịch hằng ngày ở Zimbabwe bằng USD; ZWG không neo với USD và đã mất giá mạnh từ 2024. |

## 6. `diff` giữa bản cũ và bản mới của `region_currency.dart`

Lệnh: `diff SP/region_currency.before.dart lib/core/format/region_currency.dart` (sau `dart format lib`, không có file nào bị đổi thêm). Bản lưu: `SP/ship-run7/diff_run7.txt`.

```
6,9c6,18
< /// Nguồn: CLDR (`supplementalData`, `currencyData`), lấy qua thư viện Python
< /// Babel 2.18.0 (CLDR 47), bằng lệnh
< /// `get_territory_currencies(R, date(2026, 10, 2), tender=True,
< /// non_tender=False)` cho mỗi vùng `R`. Ngày lấy dữ liệu: 2026-10-02.
---
> /// Nguồn: CLDR 47 (`supplementalData`, `currencyData`), lấy qua thư viện
> /// Python Babel 2.18.0, bằng lệnh `get_territory_currencies(R,
> /// date(2026, 10, 2), tender=True, non_tender=False)` cho mỗi vùng `R`.
> /// 2026-10-02 chỉ là ngày truy vấn truyền cho Babel, không phải ngày cập nhật
> /// dữ liệu. CLDR 47 cũ hơn CLDR 48 mà intl 0.20.3 của app dùng; script đối
> /// chiếu bảng với `DEF_CURRENCY_CODE` của từng locale intl theo vùng của
> /// locale đó.
> ///
> /// Ghi đè sau bước chọn (thắng dữ liệu CLDR):
> /// - `BG` ra `EUR`: Bulgaria dùng EUR từ 2026-01-01; CLDR 47 chưa có, intl
> ///   0.20.3 (CLDR 48) đã có.
> /// - `ZW` ra `USD`: phần lớn giao dịch hằng ngày ở Zimbabwe bằng USD; ZWG
> ///   không neo với USD và đã mất giá mạnh từ 2024.
13,14c22,24
< /// `BT` ra `BTN`) thì lấy mã đó; không thì lấy mã đầu tiên theo thứ tự Babel
< /// (nếu có từ hai mã bắt đầu bằng mã vùng thì lấy mã đầu tiên trong số đó).
---
> /// `BT` ra `BTN`) thì lấy mã đó; không thì lấy mã có ngày bắt đầu lưu hành
> /// (`from`) sớm nhất, vì Babel trả ứng viên theo thứ tự `from` (nếu có từ hai
> /// mã bắt đầu bằng mã vùng thì cũng lấy mã có `from` sớm nhất trong số đó).
43c53
<   'BG': 'BGN',
---
>   'BG': 'EUR',
276c286
<   'ZW': 'ZWG',
---
>   'ZW': 'USD',
```

Khác biệt chỉ nằm ở khối chú thích `///` và đúng 2 dòng `'BG': 'EUR',`, `'ZW': 'USD',`, đúng §1.5. Số mục của bảng: **255** (`grep -c "^  '"` ra 255; script in `Số mục của bảng: 255`), không đổi. `'PA': 'PAB'` giữ nguyên. File không có `DateTime.now()`, `Color(0x`, `Text('`, và không còn câu "Ngày lấy dữ liệu".

## 7. Kết quả các lệnh kiểm chứng

Mọi lệnh chạy với `export PATH="/opt/flutter/bin:$PATH"` trong `/home/user/mekoke`. (Flutter in cảnh báo "running flutter as root", vô hại.)

| Lệnh | Kết quả |
|---|---|
| `flutter test` trước khi sửa (mốc) | `+1243: All tests passed!` (0 rớt) |
| `dart format lib` sau khi sinh | `Formatted 69 files (0 changed)` |
| `dart format --output=none --set-exit-if-changed lib test` | thoát mã 0, `Formatted 117 files (0 changed)` |
| `flutter analyze` | `No issues found!` |
| `flutter test` (múi giờ mặc định) | `+1241 -2: Some tests failed.` (đúng 2 rớt) |
| `TZ=America/New_York flutter test` | `+1241 -2: Some tests failed.` (đúng 2 rớt, cùng 2 test) |
| `git status --short` | chỉ có các thay đổi vòng trước (3 file `lib/`, 3 file `test/`, trong đó `region_currency.dart` chưa theo dõi) và `.bangiao/`. Vòng này chỉ đổi `region_currency.dart`. `pubspec.*` không đổi (`git diff --quiet` thoát 0). |
| `graphify update .` | xong: 2241 nút, 3124 cạnh, 137 cộng đồng |

Log: `SP/ship-run7/base_default.log`, `test_default.log`, `test_ny.log`.

## 8. Test rớt thực tế

Cả hai múi giờ rớt cùng đúng 2 test, trùng danh sách kế hoạch dự kiến, cả hai trong `test/core/money_format_test.dart`, nhóm `MoneyFormat.currencyForLocale a region with several currencies gets its own`:

1. `en_ZW gives ZWG`: dòng 205, `Expected: 'ZWG'`, `Actual: 'USD'`.
2. `a language that has its own region does not leak in`: dòng 212, `expect(MoneyFormat.currencyForLocale('en-ZW'), 'ZWG')`, `Actual: 'USD'`.

Không test nào khác rớt. Cả hai là kỳ vọng cũ về ZWG, Tester sẽ sửa theo §3 kế hoạch. Tôi không sửa test. Số test sau khi Tester thêm ca `bg_BG` phải là +1244, 0 rớt.

## 9. Chỗ lệch so với kế hoạch

- Cách ngắt dòng của gạch đầu dòng ZW: lần sinh đầu dùng `textwrap.fill(width=80)` và đưa chữ "không" lên dòng đầu (đúng 80 cột), khác văn bản mẫu của kế hoạch. Đã đổi sang `width=79`; sau đó khối chú thích khớp mẫu từng byte. Không ảnh hưởng nội dung.
- Lý do của `OVERRIDES` giữ nguyên văn như kế hoạch, nên chuỗi "CLDR 47 ... intl 0.20.3 (CLDR 48)" trong lý do của BG là chữ cố định, không lấy từ biến. Phần chú thích "Nguồn" thì lấy số từ biến. Nếu đổi phiên bản Babel hay intl, nhớ sửa lý do BG bằng tay trong script. Đây là theo kế hoạch §1.1, không phải sửa thêm.
- Ngoài kế hoạch, có thêm 2 thứ trong scratchpad, đều ngoài repo: thư mục `SP/ship-run7/` chứa log và output của lần chạy này, và `SP/gen_region_currency.before.py` (bản cũ của script, để xem `diff`).
- Trạng thái git: `git status` hiện `.bangiao/danh-gia.md`, `.bangiao/ket-qua-test.md` ở trạng thái xoá (` D`) và `.bangiao/ke-hoach.md` ở trạng thái sửa (` M`) so với mốc, đều có sẵn từ trước khi tôi bắt đầu. `.bangiao/thay-doi.md` cũng ` D` trước đó; file này tôi vừa viết lại. Tôi không đụng vào các file kia.

## 10. Chỗ Tester nên soi

1. `bg_BG` ra `EUR`, `en_ZW` và `en-ZW` ra `USD`. Xoá hẳn dòng `'BG'` hoặc `'ZW'` khỏi bảng thì `bg_BG` (intl có sẵn `bg` ra EUR) và `en_ZW` (rơi xuống cuối chuỗi USD) vẫn ra đúng mã. Chỉ `expect(kRegionCurrency['BG'], 'EUR')` và `expect(kRegionCurrency['ZW'], 'USD')` mới bắt được lỗi này, nên đột biến (h), (i) phải bắt bằng test `has the entries the plan names`.
2. Các ca phải giữ nguyên: `en_US`, `de_DE`, `ja_JP`, `vi_VN`, `en_GB`, `bg_BG`, `xx`, `xx_YY`. `PA` vẫn `PAB`, `en_PA` vẫn `PAB`.
3. Chú thích nhóm `a region with several currencies gets its own` ở test cần sửa lại cho đúng (LS, NA tự phát hành khác mã Babel trả đầu tiên; PS lấy mã có `from` sớm nhất là ILS; ZW ghi đè ra USD). Số liệu `from` thực tế (xem §4): PS: ILS 1985-09-04, JOD 1996-02-12; LS: ZAR 1961, LSL 1980; NA: ZAR 1961, NAD 1993; ZW: USD 2009, ZWG 2024.
4. Chú thích đầu `region_currency.dart`: khối `///` khớp mẫu §2 từng byte; không còn "Ngày lấy dữ liệu". `test/static_rules_test.dart` quét file này (đã qua, không có `DateTime.now()`, `Color(0x`, `Text('`).
5. Đột biến (f) đến (i) làm trên bản sao ngoài repo (`SP/mut/`), không sửa file trong repo.
6. Script phụ thuộc đường dẫn `/root/.pub-cache/.../intl-0.20.3/...`; nếu máy khác không có đường dẫn này thì script không chạy được (assert/đọc file lỗi), nhưng file Dart đã sinh không bị ảnh hưởng.
