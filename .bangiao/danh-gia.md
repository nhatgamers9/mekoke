PHAN QUYET: CHOT

# Đánh giá: vòng "1A 2A 3A 4A", màn paywall xem thử (Monthly $9.99, Weekly $4.99)

> Ghi chú của điều phối viên: Reviewer không có công cụ Write nên đã gửi nguyên văn nội dung dưới đây. Điều phối viên lưu lại, không sửa chữ nào. Điều phối viên không chạy lại `flutter test`; con số 1364/1364 là của Tester (Coder cũng báo 1244/1244 trước khi có test mới). Điều phối viên đã tự bấm thử trên bản xem trước web ở 360x800: nút "See Premium" mở paywall, hai giá hiện đúng, đổi sang Weekly thì dòng điều khoản đổi theo, bấm "Try 3 days free" hiện "Purchases aren't available yet." và màn không đóng, nút X đóng paywall.

Reviewer, chặng 4 của /ship. Nhánh `claude/vigilant-archimedes-0yt6az`, mốc `4b2a0d5`. Vòng này chưa có commit nào.

## Tôi đã làm gì

- Đọc `.bangiao/ke-hoach.md`, `thay-doi.md`, `ket-qua-test.md`.
- Chạy `git status`, `git diff`, `git log`; đọc trực tiếp các file chưa theo dõi của vòng này.
- Đối chiếu với `design/mockups/steady/Paywall.dc.html` và `design/steady-ds/components/PlanOption/README.md`.
- Tự chạy hai lệnh kiểm không ghi file: `dart format --output=none --set-exit-if-changed lib test` (124 file, 0 thay đổi, exit 0) và `dart analyze` ("No issues found!", exit 0). `git status` trước và sau giống nhau.
- Không chạy `flutter test`, vì lệnh này ghi vào `.dart_tool/` và `build/`. Con số 1364/1364 là của Tester, tôi chưa tự kiểm. Tôi đếm tay số test trong các file mới: 8 + 31 + 67 + 8 + 6 = 120, khớp 1244 + 120 = 1364.
- Chỉ xét phần của vòng paywall. Phần "bản xem trước trên web" ghi riêng ở cuối.

## Kết luận ngắn

Mã khớp kế hoạch. Tôi không tìm thấy lỗi về đúng sai, bảo mật hay hiệu năng. Test có giá trị thật. Không có việc nào bắt buộc sửa trước khi chốt vòng này. Có một điểm về câu chữ sẽ thành điểm chặn ngay khi nối mua thật hoặc phát hành cho người dùng thật (mục "Ghi nhận", số 1).

## 1. Code có khớp kế hoạch không?

Có.

- `lib/features/premium/premium_plans.dart`: đúng mục 3.2. Thuần Dart, monthly 999 rồi weekly 499, `kPlanCurrency = 'USD'`, chú thích đầu file nói đây là giá tạm.
- `lib/ui/components/plan_option.dart`: đúng mục 3.3. `Material` + `RoundedRectangleBorder` (bo `SteadyRadius.lg`, viền 2 px) + `InkWell` có `customBorder`; đệm `s4`; cao tối thiểu `SteadySize.tap`; ô radio 24x24; cột giá không co giãn, mỗi dòng `maxLines: 1`; Semantics theo `icon_tile.dart`; không `LayoutBuilder`; không tham số `badge`.
- `lib/features/premium/paywall_screen.dart`: đúng mục 3.4, đủ tám phần theo thứ tự. State chỉ có gói đang chọn và một cờ chỉ có đường bật. Giá chỉ đi qua `MoneyFormat(formatLocaleOf(context), kPlanCurrency)` (dòng 49). Không `ServicesScope`, không import `lib/data/`.
- `lib/features/placeholder/placeholder_screen.dart:33-36` và `lib/features/shell/home_shell.dart:41-44, 68-74`: đúng mục 3.5. `PopScope` và `AnnotatedRegion` không đổi.
- `lib/l10n/app_en.arb:392-422`: đủ 17 khoá, nguyên văn mục 3.6 và nguyên văn mockup. Hai file sinh ra chỉ thêm, không sửa chỗ cũ.
- `lib/ui/components/steady_icon.dart:40`: thêm `check`; không thêm svg.
- Không file ngoài phạm vi nào bị vòng này đụng; `pubspec.yaml` không đổi.

Khác kế hoạch (đều đã khai, chấp nhận được):

- `home_shell.dart:42-43`: dáng xuống dòng do `dart format` quyết định, nội dung đúng. Tôi đã tự chạy `dart format`, sạch.
- `plan_option.dart:117`: dùng `?note` thay `if (note != null) note` vì lint của repo.
- Tester thêm `test/widget/paywall_fit_test.dart`, ngoài danh sách mục 6. Đây là phần thêm có ích (đo bằng phông thật), không thay test nào.

## 2. Test có giá trị thật hay viết cho có?

Có giá trị thật.

- `test/widget/paywall_test.dart` chạy qua cả app (`pumpSteadyApp`), không chỉ dựng riêng widget.
- Có đường phủ định: bấm nút chính thì chụp cả năm bảng của DB trước và sau (đủ năm bảng khai ở `lib/data/database.dart:94`), màn không đóng, `SystemNavigator.pop` không bị gọi.
- Sau mỗi lần chạm luôn kiểm đúng một gói được chọn và đúng một dòng điều khoản.
- Test `en_ZA` bắt được việc nối ký hiệu tiền bằng tay hoặc bỏ vùng của máy: kết quả đúng là `$9,99`, không phải `$9.99`.
- `test/widget/paywall_fit_test.dart` có test đối chứng "phông thật đã nạp" rồi mới đo bố cục, nên không xanh giả khi phông không nạp được.
- `test/design/assets_and_copy_test.dart` chỉ thêm một nhóm ở cuối (106 dòng thêm, 0 dòng xoá).

Chỗ yếu, không chặn:

- `test/ui/plan_option_test.dart:440-473`, trường hợp rộng 320 cỡ chữ 2.0 với Ahem: cột tên gói chỉ còn khoảng 24 px trong khi mỗi ký tự rộng 36 px. `Text` không ném lỗi khi chữ tràn, nên test xanh không chứng minh được tên gói đọc được. Trường hợp này chỉ có nghĩa với phông thật, và `paywall_fit_test.dart` có phủ 320x640.
- `test/widget/paywall_test.dart:354-364` ("no badge"): chỉ dò bốn chuỗi cứng. `PlanOption` không có tham số `badge` nên test này gần như không thể rớt.
- `test/widget/paywall_test.dart:1020-1039`: 14 locale chỉ kiểm giá thuộc một trong hai giá (`anyOf`). Giá trị chính là "không crash".

## 3. Bảo mật, hiệu năng, tính đúng đắn

- Bảo mật: không có gì để tấn công. Không mạng, không lưu trữ, không khoá bí mật, không gói thanh toán.
- Hiệu năng: không có gì đáng kể. `MoneyFormat` có bộ nhớ đệm theo cặp locale và tiền tệ.
- Đúng sai: không tìm thấy lỗi. `SliverFillRemaining(hasScrollBody: false)` dùng đúng mẫu của `lib/features/timer/interval_run_screen.dart:213` và không có `LayoutBuilder` bên trong. Paywall là route riêng nên Back đóng paywall trước; `PopScope` của `HomeShell` thuộc route bên dưới.

## Ghi nhận (không chặn vòng này)

1. Câu chữ paywall không đúng với app hiện tại. Đây là quyết định của chủ dự án, đã được báo trước; tôi nêu lại bằng mắt độc lập.
   - `lib/l10n/app_en.arb:394-398` quảng cáo âm thanh, widget và "no ads". Trong `lib/` không có âm thanh, không có widget, không có quảng cáo, không có trạng thái Premium và chưa khoá tính năng nào.
   - "Unlimited habit streaks" và "Custom fasting and interval plans" ngụ ý bản miễn phí bị giới hạn, trong khi hiện không có giới hạn nào.
   - Tab Focus ghi "This part of Steady isn't ready yet." ngay trên nút dẫn tới màn quảng cáo "Every sound".
   - Vì sao tôi không chặn: không ai mua được gì (nút chính chỉ hiện "Purchases aren't available yet."), bản build chỉ là APK thử ký bằng khoá debug, và kế hoạch yêu cầu chép nguyên văn mockup.
   - Điều kiện: điểm này phải thành điểm CHẶN ngay khi nối mua thật hoặc đưa bản build cho người dùng thật. Lúc đó hoặc sửa câu chữ cho đúng với tính năng đang có, hoặc làm xong tính năng.
   - Nút "See Premium" có trong cả bản release (không có cờ chặn), và `test/design/assets_and_copy_test.dart` cùng `test/widget/paywall_test.dart` đang khoá nguyên văn các câu này. Nên ghi một dòng nhắc vào kế hoạch của vòng nối mua.

2. Giá và điều khoản khi nối cửa hàng.
   - `paywall_screen.dart:49, 125, 152`: máy `en_AU` và `en_CA` hiện `$9.99`, dễ đọc thành đô la địa phương. Kế hoạch mục 4 số 7 đã chấp nhận.
   - `design/steady-ds/components/PlanOption/README.md` yêu cầu giá là chuỗi do Google Play Billing trả về. Khi nối cửa hàng phải bỏ `MoneyFormat` ở đây.
   - "3-day free trial", "Try 3 days free" và dòng "Free for 3 days, then..." phải theo điều kiện dùng thử của từng người do cửa hàng trả về.
   - "Restore purchase", Terms và Privacy (mockup dòng 41) phải có khi mua được.

3. `.bangiao/ket-qua-test.md:59` không khớp test đã lưu. Tester ghi đã kiểm phông thật ở 360x560, 360x640 và 320x480. `test/widget/paywall_fit_test.dart:49-57` chỉ có 360x800, 360x560 và 320x640. Hai kích thước 360x640 và 320x480 không có bằng chứng lưu lại. Nên thêm hai kích thước đó vào vòng lặp, hoặc sửa câu trong báo cáo.

4. Tên gói ở cỡ chữ 2.0 (ước tính của tôi, chưa chạy thử). `plan_option.dart:91-106` để cột giá rộng theo nội dung, nên trên máy rộng 360 cột tên gói còn khoảng 125 px, trong khi "Monthly" cỡ 36 px rộng khoảng 135 px. Tên gói có thể bị bẻ giữa từ ("Monthl" rồi "y"). Kế hoạch cho phép tên gói xuống dòng, và không test nào ghim cách xuống dòng. Nên nhìn tận mắt trên máy thật ở cỡ chữ 200%.

5. Nút X nằm đầu thân cuộn (`paywall_screen.dart:73-81`), đúng kế hoạch. Khi đã cuộn xuống thì phải cuộn lên mới thấy X; Back của Android vẫn đóng được.

6. Lỗi tràn 36 px ở tab Focus tại 360x560 cỡ chữ 2.0 chỉ xảy ra với phông Ahem. `placeholder_screen.dart:24-38` là `Column` không cuộn, có từ trước vòng này. Với phông thật thì vừa (`paywall_fit_test.dart` phủ 360x560 cỡ chữ 2.0).

7. CI trên Linux chưa chạy với các thay đổi này. Mọi kết quả là từ máy Windows.

## Phần ngoài phạm vi: bản xem trước trên web

Không tính vào phán quyết. Không xung đột với vòng paywall: hai nhóm file không trùng nhau.

- Nhóm của việc kia: `lib/data/database.dart`, `lib/main.dart`, `test/static_rules_test.dart`, `README.md`, `.gitignore`, `.metadata`, `analysis_options.yaml`, `web/`, `tool/`.
- Nên commit tách riêng hai việc.
- Con số 1244 và 1364 đều đo trên cây đã có bản sửa `test/static_rules_test.dart` của việc kia (đổi `\` thành `/` trong đường dẫn). Theo cách tôi đọc diff, thiếu bản sửa đó thì test này rớt khi chạy trên Windows; CI Linux không bị ảnh hưởng.
