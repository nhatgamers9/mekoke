PHAN QUYET: CHOT

# Đánh giá: vòng "sửa tiếp", tiền tệ theo vùng (BG ra EUR, ZW ra USD)

> Ghi chú của điều phối viên: Reviewer không có công cụ Write nên đã gửi nguyên văn nội dung dưới đây. Điều phối viên lưu lại, không sửa chữ nào. Sau khi Tester xong, điều phối viên đã chạy lại độc lập:
> - `flutter analyze`: "No issues found!".
> - `flutter test`: +1244 "All tests passed!".
> - `TZ=America/New_York flutter test`: +1244 "All tests passed!".

Reviewer, chặng 4 của /ship. Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `267a46a`. Viết tắt `SP` = `/tmp/claude-0/-home-user-mekoke/cc7bfc32-2202-5695-aafd-72552f98ca86/scratchpad`.

Tôi chỉ đọc. Cụ thể:
- Chạy `git status`, `git diff --stat 267a46a`.
- Diff `SP/region_currency.before.dart` với `lib/core/format/region_currency.dart`.
- Diff `SP/mut/base/` (bản chốt vòng trước) với 5 file `lib/` và `test/` hiện tại, để tách riêng phần của vòng này.
- Đọc `SP/gen_region_currency.py`.
- Tra Babel 2.18.0 bằng `python -B` (không ghi file). Đối chiếu bảng với intl bằng một cách khác với script: `babel.Locale.parse` thay cho `split('_')` kết hợp `language_aliases`.
- Chạy logic của script trong bộ nhớ, cắt trước bước ghi file, `OUT` trỏ vào `/dev/null`, để thử ghi đè thừa.
- Không chạy `flutter test`, vì lệnh này ghi vào `.dart_tool/`. Số +1244 lấy từ dòng cuối của `SP/ship-run7/tester_default.log`, `tester_ny.log` và 5 log trong `SP/ship-run7/mutlogs/`.

## Tóm tắt
- Hai việc "Cần sửa" của vòng trước đã xong, đúng cách đã đề xuất: `BG` ra `EUR` và `ZW` ra `USD` bằng `OVERRIDES` trong script, rồi sinh lại bảng. `PA` vẫn `PAB`.
- So với bản cũ, bảng chỉ khác khối `///` và đúng 2 dòng: dòng 53 `'BG': 'EUR',` và dòng 286 `'ZW': 'USD',`. Bảng vẫn 255 mục.
- Vòng này chỉ đổi `lib/core/format/region_currency.dart` và 6 chỗ trong `test/core/money_format_test.dart`. Các file sau giống hệt bản chốt vòng trước: `money_format.dart`, `transaction_row.dart`, `money_components_test.dart`, `money_screen_test.dart`. `pubspec.*` không đổi.
- Không có hồi quy. Có vài điểm nên làm để script bền hơn cho lần sau, nhưng không chặn.

## Ba câu hỏi

### Code có khớp kế hoạch không?
Có.
- **§1.1:** `OVERRIDES` đúng nguyên văn. Phần ghi đè được áp sau vòng chọn và có đủ 4 assert ở script dòng 115–120. `before = dict(table)` được lưu trước khi áp.
- **§1.2:** script dòng 123–133 kiểm hai điều: thứ tự mã khi gọi kèm `include_details=True` trùng với `cands`, và `from` không giảm (`None` coi là `date.min`). Logic chọn không đổi.
- **§1.3:** `read_intl_currencies` và `intl_region` đúng đặc tả.
  - Regex `new NumberSymbols\(` không khớp `new CompactNumberSymbols(` ở dòng 2295 trở đi của file intl, nên không đếm trùng 119 locale.
  - Toàn file có đúng 119 dòng `DEF_CURRENCY_CODE`.
- **§1.5:** mọi assert đều nằm trước `open(OUT, 'w')` ở dòng 204.
- **§2:** chú thích khớp mẫu. Dòng dài nhất 79 ký tự (đếm theo ký tự Unicode). Đã bỏ câu "Ngày lấy dữ liệu".

### Test có giá trị thật hay chỉ viết cho có?
Có giá trị thật.
- Log đột biến khớp bảng của Tester: (f) `+71 -2`, (g) `+70 -3`, (h) `+72 -1`, (i) `+72 -1`.
- Với (h) và (i), test duy nhất rớt là `has the entries the plan names`. Điều này xác nhận hai dòng `expect(kRegionCurrency['BG'] / ['ZW'])` ở `test/core/money_format_test.dart` dòng 350–351 là chốt chặn duy nhất cho lỗi xoá hẳn dòng, không phải dòng thừa.
- `bg_BG` được xếp vào nhóm "Giữ nguyên như trước khi có bảng theo vùng". Xếp vậy là đúng, vì trước khi có bảng, `bg_BG` đi qua intl `bg` và ra EUR.
- Chú thích nhóm ở dòng 191–196 khớp số liệu Babel tôi tự tra: ZAR 1961-02-14, LSL 1980-01-22, NAD 1993-01-01, ILS 1985-09-04, JOD 1996-02-12, USD 2009-04-12, ZWG 2024-06-25.

### Bảo mật, hiệu năng, tính đúng đắn
- **Bảo mật, hiệu năng:** không thay đổi gì. Vòng này chỉ đổi 2 giá trị trong một map `const`.
- **Đúng đắn:** USD và EUR đều có 2 chữ số thập phân, giống ZWG và BGN, nên số tiền đã lưu theo đơn vị nhỏ nhất không bị lệch.

## Các điểm điều phối viên hỏi

1. **BG ra EUR, ZW ra USD có đúng không?** Đúng.
   - Babel 2.18.0 (CLDR 47) cho BG chỉ có BGN, `from` 1999-07-05, không có `to`. Intl 0.20.3 thì khác:
     - `number_symbols_data.dart` dòng 10 ghi "CLDR ver. 48";
     - dòng 194 cho `bg` là `EUR`;
     - `pubspec.lock` dòng 335 ghi `version: "0.20.3"`.
   - Bulgaria dùng EUR từ 2026-01-01.
   - ZW ra USD là lựa chọn sản phẩm, đã nêu lý do ở vòng trước. Intl không có locale nào thuộc vùng ZW, nên không có nguồn ngoài nào mâu thuẫn.

2. **Chú thích đầu file có chính xác không?** Có.
   - CLDR 47 là của Babel, CLDR 48 là của intl 0.20.3. Cả hai số đều đúng.
   - Danh sách ghi đè khớp `OVERRIDES`.
   - 2026-10-02 được ghi rõ là ngày truy vấn.
   - Câu "Babel trả ứng viên theo thứ tự `from`" đúng: script assert điều này cho cả 7 vùng nhiều ứng viên, và lần chạy không hỏng assert.
   - Câu "nếu có từ hai mã bắt đầu bằng mã vùng thì cũng lấy mã có `from` sớm nhất" đúng với `own[0]`, vì `own` giữ thứ tự của `cands`.

3. **Bước đối chiếu với intl có đúng và đủ không?**
   - **Đúng:** cách đối chiếu độc lập của tôi cho cùng kết quả: trước ghi đè chỉ lệch `bg (BG): BGN và EUR`, sau ghi đè 0 lệch. `es_419` bị bỏ vì là vùng số. Các locale `in`, `iw`, `tl`, `no`, `no_NO`, `sr_Latn` đều ra đúng vùng.
   - **Khi đổi Babel thì bắt được:**
     - script dừng ngay ở dòng 14 (`assert babel.__version__ == '2.18.0'`);
     - sau khi nâng assert, nếu CLDR mới đã có BG là EUR thì dòng 119 dừng với "ghi đè thừa: BG".
   - **Khi đổi intl thì chưa bắt được.** Xem mục "Nên làm sau", điểm 1 và 2.

4. **Ghi đè thừa thì script có dừng không?** Có, và dừng trước khi ghi file. Tôi đã thử trong bộ nhớ:
   - thêm `'US': ('USD', …)` thì ra "ghi đè thừa: US";
   - thêm `'PA': ('PAB', …)` thì ra "ghi đè thừa: PA";
   - thêm `'XQ': ('EUR', …)` thì ra "ghi đè cho vùng không có trong bảng: XQ".

5. **Test mới có giá trị thật không?** Có, xem phần "Ba câu hỏi" ở trên.

6. **Có hồi quy nào khác không?** Không.
   - Diff bảng cũ và mới chỉ có 2 dòng giá trị.
   - Các ca phải giữ nguyên đều vẫn qua: `en_US`, `de_DE`, `ja_JP`, `vi_VN`, `en_GB`, `bg_BG`, `xx`, `xx_YY`, `en_PA`.
   - +1244, 0 rớt ở cả hai múi giờ (theo log).

## Nên làm sau (không chặn, ngoài phạm vi vòng này)

1. **`SP/gen_region_currency.py` dòng 18–20:** `INTL_SYMBOLS` ghim cứng `intl-0.20.3`, và script không đọc `pubspec.lock`.
   - Trong khi đó `pubspec.yaml` dòng 19 để `intl: any`, còn `flutter_localizations` ghi `intl: ^0.20.3`. Nên chỉ cần `flutter pub upgrade` hoặc nâng Flutter là intl có thể đổi phiên bản mà không ai chạy lại script.
   - Kể cả khi có người chạy lại, script vẫn đọc bản 0.20.3 trong cache, và chú thích dòng 10 vẫn ghi "intl 0.20.3 của app dùng", tức là sai.
   - **Cách sửa:** đọc `version:` của khối `intl:` trong `/home/user/mekoke/pubspec.lock`, rồi dựng đường dẫn từ đó, hoặc assert nó khớp với `intl_version`.

2. **Script dòng 150–155:** lệch sau ghi đè chỉ được in ra (đúng §1.3 của kế hoạch), nên phải có người đọc output mới thấy.
   - **Cách sửa:** thêm `EXPLAINED_MISMATCHES: dict[str, str]` (locale → lý do (B) hoặc (C)), rồi đặt hai assert trước bước ghi file:
     - mọi locale trong `mismatch_after` phải nằm trong danh sách này;
     - mọi khoá trong danh sách phải vẫn còn lệch, để danh sách không bị thừa.

3. **Script dòng 180:** câu "CLDR {cldr} cũ hơn CLDR {intl_cldr}" được in vô điều kiện.
   - **Cách sửa:** thêm `assert int(cldr) < int(intl_cldr)`, hoặc đổi câu theo điều kiện. Ngoài ra, lý do của BG ở dòng 24–25 ghi cứng "intl 0.20.3 (CLDR 48)" (Coder đã nêu).

4. **Các chỗ vặt trong script:**
   - Dòng 169: biến `cldr_text` không còn được dùng, nên xoá. Nếu `cldr` là `None` thì chú thích sẽ in "CLDR None".
   - Dòng 178–179: ngày `date(2026, 10, 2)` và chuỗi `2026-10-02` đang là chữ cố định, nên lấy từ `DATE`.
   - Các kiểm tra đều dùng `assert`, nên chạy `python -O` thì mất hết. Nên đổi sang `raise SystemExit(...)`.

5. **Script nằm ngoài repo:** trong khi đó `region_currency.dart` lại ghi "File do script sinh, không sửa tay". Đây là quyết định của các vòng trước, nên để người dùng hoặc Planner quyết, ví dụ đưa vào `tool/gen_region_currency.py`.

6. **Tuỳ chọn:** thêm test Dart so `kRegionCurrency` với `numberFormatSymbols` của intl cho các locale có vùng rõ, như `en_GB`, `de_CH`, `pt_BR`.
   - Test này sẽ bắt được lệch khi nâng intl mà không cần script.
   - Nó không bắt được `bg`, vì intl chỉ có `bg` không kèm vùng. Vì vậy test này không thay được dòng 350–351.
