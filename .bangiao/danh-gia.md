PHAN QUYET: CAN SUA

# Đánh giá: GĐ3 phần 1, tab Money (theo dõi chi tiêu)

> Ghi chú của điều phối viên: Reviewer không có công cụ Write nên đã gửi nguyên văn nội dung dưới đây; điều phối viên lưu lại không sửa chữ nào. Sau đó điều phối viên kiểm thêm hai việc:
> - Chạy độc lập sau khi Tester xong:
>   - `flutter analyze`: "No issues found!".
>   - `flutter test`: +1188, "All tests passed!".
>   - `TZ=America/New_York flutter test`: +1188, "All tests passed!".
> - Xác nhận lỗi ở mục 1 bằng một script intl chạy thật. Kết quả: `es_AR` → `es` → EUR; `ar_SA` → `ar` → EGP; `en_PH` và `en_VN` → `en` → USD; `fr_MA` → `fr` → EUR. Các locale `en_US`, `de_DE`, `vi_VN` ra đúng.

Reviewer, chặng 4 của /ship. Nhánh `claude/vigilant-archimedes-0yt6az`, so với mốc `d88adf6`.
- Tôi chỉ đọc: `git diff`, `git status`, các file mới, và mã nguồn `intl 0.20.3` cùng Flutter SDK để kiểm hành vi.
- Tôi không chạy `flutter test`, vì lệnh này ghi vào `.dart_tool/` và `build/`. Con số +1188, 0 rớt là theo báo cáo của Tester.

## Tóm tắt
- Code khớp kế hoạch gần như từng dòng. Tám chỗ lệch mà Coder ghi ở mục 5 của `thay-doi.md` đều hợp lý.
- Định hướng "chỉ theo dõi chi tiêu" được giữ đúng:
  - Bảng không có cột `kind`.
  - Không có key nào về thu nhập, tiết kiệm, hạn mức hay chuyển tiền.
  - `TransactionRow` không có `kind`.
  - Tab Money không dùng màu `tide`.
- Test kiểm được thật, không viết cho có: 40/40 đột biến bị bắt, có ca đối chứng, có ca phải thất bại, có bắt log SQL.
- Còn hai việc phải sửa trong một vòng ngắn:
  - một lỗi đúng đắn để lại hậu quả lâu dài: tiền tệ mặc định sai ở nhiều vùng, và giá trị sai bị lưu cố định;
  - một lỗi trợ năng nhỏ.

## Cần sửa

### 1. Tiền tệ mặc định bỏ mất vùng của máy (bắt buộc)
- Chỗ lỗi: `lib/core/format/money_format.dart`, dòng 62–66 (`currencyForLocale`).
- Nơi gọi: `lib/features/money/money_screen.dart`, dòng 95–100.

**Vấn đề.** `Intl.verifiedLocale(tag, NumberFormat.localeExists, …)` chỉ giữ được vùng khi intl có sẵn đúng cặp `ngôn ngữ_VÙNG`.
- intl 0.20.3 chỉ có khoảng 20 cặp như vậy: `en_US`, `en_GB`, `de_AT`, `es_MX`, `zh_TW`, …
- Khi không có cặp, hàm rơi về ngôn ngữ trần, rồi lấy `DEF_CURRENCY_CODE` của ngôn ngữ đó.
- Theo `intl-0.20.3/lib/number_symbols_data.dart`: `es` ra EUR, `ar` ra EGP, `en` ra USD, `fr` ra EUR, `pt` ra BRL, `ru` ra RUB.

Kết quả:

| Máy | Hiện ra | Đúng ra |
|---|---|---|
| `es_AR`, `es_CO`, `es_CL`, `es_PE` | EUR | ARS, COP, CLP, PEN |
| `ar_SA`, `ar_AE` | EGP | SAR, AED |
| `en_PH`, `en_NG`, `en_PK` | USD | PHP, NGN, PKR |
| `en_VN` (iPhone tiếng Anh, vùng Việt Nam) | USD | VND |
| `fr_MA`, `pt_AO`, `ru_KZ` | EUR, BRL, RUB | MAD, AOA, KZT |

**Hậu quả.**
- Giá trị sai được ghi vào prefs `money.currency` ở lần mở đầu và không bao giờ được tính lại (`lib/data/prefs_repository.dart`, dòng 74).
- Trước GĐ5 không có màn nào để người dùng đổi tiền tệ.
- Sang GĐ5, đổi giữa hai tiền tệ có số chữ số thập phân khác nhau (ví dụ EUR 2 chữ số sang CLP 0 chữ số) sẽ làm sai cả các số tiền đã lưu theo đơn vị nhỏ nhất.

**Vì sao vẫn phải sửa dù Coder làm đúng kế hoạch.**
- Q2 đã chốt "lấy tiền tệ theo vùng của máy". Code hiện tại chưa làm được điều đó, nên sửa là làm cho đúng quyết định đã chốt, không phải đổi quyết định.
- Lỗi bắt nguồn từ thuật toán ghi trong kế hoạch §5.2; Coder làm đúng như kế hoạch.
- Test hiện có chỉ thử các locale mà intl có sẵn cặp, nên không bắt được lỗi này.
- App chưa phát hành, chưa có máy nào lưu sai. Sửa bây giờ là rẻ nhất.

**Cách sửa (không thêm package).**
1. Tạo `lib/core/format/region_currency.dart`, chứa `const Map<String, String> kRegionCurrency`:
   - khoá là mã vùng ISO 3166-1 alpha-2, giá trị là mã tiền ISO 4217;
   - lấy tiền đang lưu hành theo bảng currencyData trong `supplementalData` của CLDR;
   - khoảng 250 mục.
2. Trong `currencyForLocale`:
   - tách tag theo `_` hoặc `-`;
   - lấy subtag vùng (2 chữ cái hoặc 3 chữ số), bỏ subtag script 4 chữ cái như `Hant`;
   - đổi vùng sang chữ in hoa rồi tra bảng; có thì trả về;
   - không có thì giữ nguyên logic hiện tại (dựa vào intl, cuối cùng là USD).
3. Các trường hợp đang đúng phải giữ nguyên: `en_US` ra USD, `de_DE` ra EUR, `ja_JP` ra JPY, `vi_VN` ra VND, `en_GB` ra GBP, `xx` và `xx_YY` ra USD.
4. Không cần đổi chữ ký hàm, cũng không cần sửa `money_screen.dart`.

**Test (phần của Tester).**
- Trong `test/core/money_format_test.dart`, nhóm `MoneyFormat.currencyForLocale` (dòng 122–144):
  - thêm các ca: `es_AR` ra ARS, `es_CO` ra COP, `ar_SA` ra SAR, `en_PH` ra PHP, `en_VN` ra VND, `fr_MA` ra MAD, `zh_Hant_TW` ra TWD, `ru_KZ` ra KZT;
  - thêm một ca kiểm mọi giá trị trong bảng đều khớp `^[A-Z]{3}$`, vì `loadCurrency` sẽ ghi đè giá trị không khớp.
- Trong `test/widget/money_screen_test.dart`, nhóm `Money tab: currency` (từ dòng 1016):
  - `setDeviceLocale(Locale('es', 'AR'))` thì prefs là `ARS`;
  - `Locale('en', 'VN')` thì prefs là `VND`.

**Phương án khác.** Nếu người dùng không muốn có bảng này, phương án còn lại là Q2(c): hỏi tiền tệ ở lần mở đầu. Phương án đó cần người dùng quyết định.

### 2. `TransactionRow` chạm được nhưng không có vai trò "nút" (nhỏ, sửa cùng vòng)
- Chỗ lỗi: `lib/ui/components/transaction_row.dart`, dòng 32–33.
- `InkWell` chỉ cho hành động `tap`, không cho cờ `button` (xem `flutter/lib/src/material/ink_well.dart`, khoảng dòng 1401). TalkBack vì vậy không đọc hàng khoản chi là "nút".
- Component cùng loại `StreakCard` đã làm đúng (`lib/ui/components/streak_card.dart`, dòng 64–66).

Sửa:
```dart
return MergeSemantics(
  child: Semantics(
    button: onTap != null,
    child: Material(
      ...
```

Test:
- Trong `test/ui/money_components_test.dart`, dòng 547 đổi thành `isSemantics(isButton: true, hasTapAction: true)`.
- Thêm một ca `onTap: null` thì không có `isButton`.

## Ba câu hỏi

### Code có khớp kế hoạch không?
Có. Tôi đã đối chiếu từ §4 tới §8 của kế hoạch.

- **Schema.**
  - So với v2, `drift_schema_v3.json` chỉ thêm đúng một entity là `money_entries`.
  - `schema_v3.dart` có `CHECK (amount_minor BETWEEN 1 AND 999999999999)`.
  - Không đổi: `schema_v1`/`schema_v2`, `drift_schema_v1`/`v2`, `pubspec.*`, `assets/`, `design/`.
  - `onUpgrade` giữ khối `from < 2` và thêm `from < 3`.
- **Repository.**
  - Mọi stream xếp theo `date DESC, createdAt DESC, id DESC`.
  - Số tiền hoặc ghi chú sai thì ném `ArgumentError`.
  - `update` không đổi `createdAt`.
  - `delete` và `update` trả `false` khi không có `id`.
- **`loadCurrency`:** không bao giờ ném lỗi, đúng §4.4.
- **`AmountInput`:** đúng bảng `press`. Đã kiểm `fromMinor`/`toMinor`, ví dụ (5, 2) ra "0.05", "12." ra 1200.
- **Màn hình và component:** đúng §6 và §7.
- **Các chỗ lệch Coder đã ghi**, đều chấp nhận được:
  - `IconTile` ô "More" có thêm `onTap`. Đúng: vì có `excludeSemantics` nên thiếu `onTap` thì TalkBack không bấm được.
  - `_busy` cho cả `_pickDate` và `_editNote`.
  - `ConstrainedBox` cho tổng mỗi ngày.
  - `StreamBuilder` ở màn Expenses.
- **Theo dõi chi tiêu:** không còn sót phần thu nhập hay tiết kiệm.
  - Grep trong `lib/` không thấy income, saving, budget hay transfer ở phần Money.
  - Test copy khoá điều này.

### Test có giá trị thật hay chỉ viết cho có?
Có giá trị thật.

- **Đột biến:** 40/40 bị bắt, gồm:
  - `previousMonth` ở tháng 1;
  - `inRange` ở ngày cuối tháng;
  - bỏ chốt `_busy`;
  - quên huỷ subscription (bắt qua log SQL);
  - `decimalsFor` luôn trả 2;
  - lưới danh mục thêm 12px, đo với phông thật.
- **Migration:** kiểm giá trị từng cột của dữ liệu cũ, không chỉ đếm dòng. CHECK được thử ở cả hai biên, bằng cả SQL thô lẫn API của Drift.
- **Bộ quét màu:** tôi xác nhận Tester đã sửa thật.
  - Bản hiện tại duyệt mọi widget con (`byWidgetPredicate((_) => true)`, `skipOffstage: false`).
  - Có ca đối chứng phải thấy màu đỏ ở nút Delete (`test/widget/money_entries_test.dart`, dòng 827–844).
  - Đột biến M16 bị bắt.
  - Còn hở: chưa xét `ColoredBox`, `Icon`, `TextSpan`, `ShapeDecoration`. Hiện chưa có code Money nào dùng các thứ này.
- **Chỗ test chưa phủ:** vùng không có cặp trong intl (mục 1), và cờ `button` (mục 2).

### Có vấn đề gì về bảo mật, hiệu năng, tính đúng đắn không?

**Bảo mật:** không có gì đáng lo.
- App offline.
- Mọi truy vấn đi qua Drift với tham số được bind.
- Ghi chú bị giới hạn 60 grapheme.
- Tiền tệ trong prefs được kiểm bằng regex trước khi dùng.
- Không log dữ liệu người dùng.

**Đúng đắn**, những điểm đã kiểm:
- Tiền lưu bằng số nguyên.
- `formatScaled` có chia số thực, nhưng vẫn chính xác tới khoảng 1e13 đơn vị tiền. Intl tách phần nguyên rồi làm tròn phần lẻ, nên ví dụ 1005/100 vẫn ra 10.05.
- JPY 0 chữ số thập phân, KWD 3 chữ số.
- `previousMonth` ở tháng 1 ra tháng 12 năm trước. Ngày cuối tháng tính bằng `DateTime.utc(y, m+1, 0)`.
- `totalsByCategory`: tổng bằng nhau thì xếp theo thứ tự enum.
- Qua nửa đêm: cùng tháng thì chỉ `setState`; sang tháng khác thì nghe lại stream, kể cả khi đồng hồ lùi.
- Ngày so bằng chuỗi ISO.

**Vòng đời:**
- `dispose` huỷ cả hai subscription và gỡ listener `today`.
- Có kiểm `mounted` sau mọi `await`.
- `Navigator` và `l10n` được lấy trước `await`.
- `_busy` đứng đầu `_save`, `_pickDate`, `_editNote`, `_delete`, và được bật trước hộp thoại.
- Lúc route đang đóng, `_busy` đã nhả nhưng không bấm lại được, vì `ModalRoute` chặn chạm khi animation đang chạy ngược.

**Hiệu năng:** ổn ở quy mô cá nhân.
- `MoneyFormat` và `NumberFormat` có cache.
- Tab Money chỉ đọc hai tháng và 5 dòng gần nhất.
- Màn Expenses đọc mọi dòng rồi gom trong bộ nhớ; `ListView.builder` chỉ dựng phần đang hiện. Khi có hàng chục nghìn dòng thì nên phân trang.

## Các câu điều phối viên hỏi

**Máy `de_DE` hiện "€12.40":** chấp nhận được, không phải lỗi.
- Q2 đã chốt "cách viết số theo locale định dạng của app, cùng quy tắc với ngày tháng".
- App chỉ có `en`, nên ngày là "Oct 2" và số là "€12.40", hai thứ nhất quán với nhau.
- Khi thêm bản dịch `de`, `formatLocaleTag` tự trả `de_DE`, và số sẽ thành "12,40 €".
- Phần sai thật nằm ở việc chọn tiền tệ (mục 1), không ở cách viết số.

**Kiểm bố cục bằng `FontLoader`:** hợp lý.
- Có ca đối chứng chứng minh phông thật đã nạp: nhãn "Groceries" rộng dưới 70 và nằm trên một dòng.
- Tách thành file riêng nên không ảnh hưởng các test dùng Ahem.
- Đột biến M31 bị bắt.
- Giới hạn: chỉ dư 8px, và phép đo không có inset hệ thống. Trên máy 360×800 thật, thanh trạng thái 24px và thanh điều hướng 24–48px làm vùng cuộn hụt 48–72px. Hàng Date/Note bị che một phần và phải cuộn.
- Tiêu chí của kế hoạch đạt đúng theo chữ, nhưng chưa đạt ý định "nhìn thấy hết mà không cuộn". Người dùng quyết có siết hay không. Nếu siết, có thể lấy lại khoảng 40px:
  - đĩa `IconTile` 64 → 56;
  - phím keypad 56 → 52;
  - đệm đáy `s6` → `s4`.
- Không bắt buộc ở vòng này.

**Bốn quan sát ở mục 8 của Tester:**
1. Thiếu cờ `button`: đồng ý, đã chuyển thành mục cần sửa 2.
2. Ô ghi chú bỏ ký tự xuống dòng khi dán: đúng, nhưng không sửa được bằng `inputFormatters`.
   - `EditableText` luôn đặt `singleLineFormatter` trước các formatter khác (`flutter/lib/src/widgets/editable_text.dart`, dòng 967–972), nên formatter riêng không bao giờ thấy ký tự xuống dòng.
   - Muốn sửa phải chuyển sang ô nhiều dòng như Check-in.
   - Hậu quả nhỏ, để sau.
3. Trạng thái Save mờ không quan sát được: chấp nhận. Hành vi đã được khoá bằng các test bấm nhiều lần (thêm, sửa, sau khi lỗi) và đột biến M08.
4. graphify chưa cập nhật:
   - `graphify-out/` nằm trong `.gitignore`.
   - Đồ thị được dựng lúc 12:09, sau lần sửa `lib/` cuối (11:57), nên chỉ thiếu các file test mới.
   - Điều phối viên chạy `graphify update .` sau vòng sửa là đủ.

## Ghi nhận cho các giai đoạn sau (không chặn)
- **Tiền tệ có 4 chữ số thập phân (CLF, UYW):** 9 chữ số phần nguyên cộng 4 chữ số thập phân vượt `kMaxAmountMinor`, nên Save sẽ báo lỗi. Hiện không xảy ra được, vì không vùng nào mặc định ra hai mã này. Khi làm màn chọn tiền tệ ở GĐ5, giới hạn nhập theo `kMaxAmountMinor` hoặc loại hai mã này.
- **Đổi tiền tệ ở GĐ5:** phải quy đổi `amountMinor` khi số chữ số thập phân khác nhau, hoặc chặn việc đổi khi đã có dữ liệu.
