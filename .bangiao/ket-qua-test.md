# Kết quả test: vòng sửa tiếp, tiền tệ theo vùng (BG ra EUR, ZW ra USD)

Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `267a46a`. Không commit, không push, không đổi nhánh.
Viết tắt: `SP` = `/tmp/claude-0/-home-user-mekoke/cc7bfc32-2202-5695-aafd-72552f98ca86/scratchpad`.

**Kết luận: XANH HẾT.** `+1244`, 0 rớt ở cả hai múi giờ. Không có lỗi nào trong `lib/` cần chuyển cho Reviewer. Tester chỉ sửa đúng một file: `test/core/money_format_test.dart`. `lib/`, `pubspec.*` và các file test khác không bị đụng.

Số test: mốc Coder `+1241 -2` (2 test rớt là kỳ vọng cũ về ZWG), sau khi sửa 2 test và thêm ca `bg_BG` thành `+1244`. File `money_format_test.dart` từ 72 lên 73 test (đã chạy riêng: `+73: All tests passed!`).

## 1. Test đã sửa và đã thêm (`test/core/money_format_test.dart`)

Đã xác nhận hai test rớt như Coder báo trước khi sửa. Cả hai là kỳ vọng cũ về ZWG, không phải code sai: đặc tả mới (kế hoạch §1.1, §3) yêu cầu ZW ra USD.

**Sửa (2 test, sang USD):**
- Nhóm `a region with several currencies gets its own`, ca `en_ZW`: `'ZWG'` thành `'USD'` (tên test thành `en_ZW gives USD`).
- Test `a language that has its own region does not leak in`: `expect(MoneyFormat.currencyForLocale('en-ZW'), 'ZWG')` thành `'USD'`. Chú thích đổi vế `en_ZW: tiền Zimbabwe` thành `en-ZW: ZW bị ghi đè ra USD, nhận cả "-"`.

**Viết lại chú thích nhóm** `a region with several currencies gets its own`, theo số liệu `from` Coder đã ghi ở `thay-doi.md` §4:
- LS, NA: lấy mã tự phát hành (LSL, NAD), không phải mã Babel trả đầu tiên (ZAR, `from` 1961, sớm hơn LSL 1980 và NAD 1993);
- PS: không mã nào bắt đầu bằng mã vùng, lấy mã có `from` sớm nhất: ILS 1985, không phải JOD 1996;
- ZW: ngoại lệ, bị ghi đè ra USD (USD `from` 2009, ZWG `from` 2024), xem chú thích của `kRegionCurrency`.

**Thêm (1 test mới và 2 dòng khẳng định):**
- `'bg_BG': 'EUR'` vào map `cases` của nhóm `the region of the phone wins over its language`, ngay sau `'en_GB': 'GBP'` (trong phần "Giữ nguyên như trước khi có bảng theo vùng"). Sinh thêm test `bg_BG gives EUR`. Đây là test duy nhất làm tăng số lượng (1243 lên 1244).
- Trong test `has the entries the plan names` (nhóm `kRegionCurrency`): `expect(kRegionCurrency['BG'], 'EUR');` và `expect(kRegionCurrency['ZW'], 'USD');`, kèm chú thích vì sao cần hai dòng này (xoá hẳn dòng BG hoặc ZW thì `bg_BG` và `en_ZW` vẫn đúng nhờ intl).

Không nới kỳ vọng nào khác. `thay-doi.md` không ghi ghi đè nào ngoài BG, ZW nên không có ca bổ sung theo §3.4.

**Các ca phải giữ nguyên, vẫn qua:** `en_US` USD, `de_DE` EUR, `ja_JP` JPY, `vi_VN` VND, `en_GB` GBP, `bg_BG` EUR (ca mới), `xx` USD, `xx_YY` USD. `en_PA` vẫn ra `PAB`.

## 2. Gây lỗi cố ý (trên bản sao ngoài repo)

Bản sao ở `SP/ship-run7/mut/` (tạo bằng `tar`, bỏ `.git`, `graphify-out`, `android`, `build`). Trước khi gây lỗi: `diff -r lib` và `diff -r test` với repo đều giống hệt; chạy `money_format_test.dart` trên bản sao: `+73: All tests passed!`. Mỗi đột biến sửa thẳng `lib/core/format/region_currency.dart` của bản sao (bằng `sed`), chạy `flutter test test/core/money_format_test.dart`, rồi chép lại bản gốc. Sau cùng `diff -r` `lib/` của bản sao với repo: giống hệt. Mỗi đột biến vẫn qua `dart analyze` (No issues found!), tức là lỗi thuần về hành vi. Log: `SP/ship-run7/mutlogs/{base,f,g,h,i}.log`.

| Đột biến | Sửa trên bản sao | Kết quả | Test rớt |
|---|---|---|---|
| (f) bỏ ghi đè BG | `'BG': 'EUR'` thành `'BGN'` | **BẮT ĐƯỢC**: `+71 -2` | `bg_BG gives EUR`; `kRegionCurrency has the entries the plan names` |
| (g) bỏ ghi đè ZW | `'ZW': 'USD'` thành `'ZWG'` | **BẮT ĐƯỢC**: `+70 -3` | `en_ZW gives USD`; `a language that has its own region does not leak in` (ca `en-ZW`); `kRegionCurrency has the entries the plan names` |
| (h) xoá hẳn dòng BG | xoá `'BG': 'EUR',` | **BẮT ĐƯỢC**: `+72 -1` | chỉ `kRegionCurrency has the entries the plan names` |
| (i) xoá hẳn dòng ZW | xoá `'ZW': 'USD',` | **BẮT ĐƯỢC**: `+72 -1` | chỉ `kRegionCurrency has the entries the plan names` |

Khớp đúng cột "Test phải bắt" của kế hoạch §3. Với (h) và (i), `bg_BG gives EUR` và `en_ZW gives USD` vẫn qua (intl một mình ra EUR cho `bg`, và `en_ZW` rơi xuống cuối chuỗi USD), nên hai dòng `expect(kRegionCurrency[...])` là chốt chặn duy nhất, đúng như Coder dự báo. Nếu bỏ hai dòng đó thì (h), (i) lọt.

## 3. Kết quả từng lệnh (chạy trong `/home/user/mekoke`, sau khi sửa test)

Múi giờ mặc định của máy là UTC (`date +%Z` ra `UTC`). Log: `SP/ship-run7/tester_default.log`, `tester_ny.log`.

| Lệnh | Kết quả | Mã thoát |
|---|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | `Formatted 117 files (0 changed)` | 0 |
| `flutter analyze` | `No issues found!` | 0 |
| `flutter test` (UTC mặc định) | **`+1244: All tests passed!`**, 0 rớt | 0 |
| `TZ=America/New_York flutter test` | **`+1244: All tests passed!`**, 0 rớt | 0 |
| `git status --short` | chỉ có 3 file `lib/` (`money_format.dart`, `transaction_row.dart`, `region_currency.dart` chưa theo dõi) và 3 file `test/` của vòng trước, cùng `.bangiao/`. Vòng này chỉ đổi `region_currency.dart` (Coder) và `money_format_test.dart` (Tester). `pubspec.yaml` và `pubspec.lock` không đổi (`git diff --quiet` thoát 0). Nhánh vẫn `claude/vigilant-archimedes-0yt6az`. | |
| `graphify update .` | xong, `graph.json`, `graph.html`, `GRAPH_REPORT.md` đã cập nhật | 0 |

Đối chiếu tiêu chí xong của kế hoạch §6: `+1244, 0 rớt` ở cả hai múi giờ (đạt); `analyze` sạch, `format` thoát 0 (đạt); `bg_BG` ra EUR, `en_ZW` và `en-ZW` ra USD (đạt); các ca giữ nguyên không đổi (đạt); bốn đột biến (f) đến (i) đều bị bắt (đạt).

## 4. Phần rớt

Không có. Hai test rớt sau Coder (`en_ZW gives ZWG`, `a language that has its own region does not leak in`) đã được sửa sang USD theo đặc tả. Sau khi sửa, không test nào rớt, nên không có gì cần chuyển cho Reviewer từ phía code.

## 5. Chỗ Reviewer nên biết

- Chú thích viết lại trong test dựa vào số `from` mà Coder ghi ở `thay-doi.md` §4 (PS: ILS 1985 và JOD 1996; LS: ZAR 1961 và LSL 1980; NA: ZAR 1961 và NAD 1993; ZW: USD 2009 và ZWG 2024). Tester không tự tra lại Babel; chỉ chép số của Coder.
- Việc bắt (h), (i) hoàn toàn dựa vào hai dòng `expect(kRegionCurrency['BG'], ...)` và `expect(kRegionCurrency['ZW'], ...)`. Nếu sau này ai gộp hoặc bỏ test `has the entries the plan names`, hai đột biến này sẽ lọt.
