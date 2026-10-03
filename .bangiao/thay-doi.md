# Thay đổi: màn paywall xem thử, Monthly $9.99 và Weekly $4.99 (Steady)

Làm đúng theo `.bangiao/ke-hoach.md`. Kế hoạch không có mục câu hỏi bỏ ngỏ. Không tạo và không sửa file nào trong `test/`. Không đụng các file ngoài phạm vi (mục 1 của kế hoạch).

## File đã tạo

- `lib/features/premium/premium_plans.dart`: `PlanPeriod`, `PremiumPlan`, `kPlanCurrency = 'USD'`, `kPremiumPlans` (monthly 999, weekly 499). Thuần Dart, không import Flutter. Chú thích đầu file nói đây là giá tạm. Đây là nơi duy nhất ghi hai mức giá.
- `lib/ui/components/plan_option.dart`: component `PlanOption` (thẻ chọn một gói). `Material` + `RoundedRectangleBorder` (`SteadyRadius.lg`, viền 2 px `lineStrong`, `amber` khi chọn) + `InkWell` có `customBorder`. Đệm `s4`, cao tối thiểu `SteadySize.tap` (`ConstrainedBox` đặt trong `InkWell`, bọc ngoài `Padding`). Ô radio 24x24, khi chọn nền và viền `amber` kèm dấu tích 16 px `onAmber`. Cột giá không `Expanded`, mỗi dòng `maxLines: 1`. Semantics chép `icon_tile.dart`, nhãn là `title, price, period[, note]`. Không `LayoutBuilder`, không tham số `badge`.
- `lib/features/premium/paywall_screen.dart`: `PaywallScreen` (StatefulWidget, state gồm gói đang chọn và cờ đã bấm nút chính). Cây widget đúng mục 3.4: `Scaffold > SafeArea > CustomScrollView > SliverFillRemaining(hasScrollBody: false) > Padding > Column`. Giá chỉ đi qua `MoneyFormat(formatLocaleOf(context), kPlanCurrency)`. Chọn chuỗi theo `PlanPeriod` bằng `switch` đủ nhánh (ba hàm cấp file `_planTitle`, `_planPeriodLabel`, `_planTerms`, theo mẫu `_moodLabel`). Không dùng `ServicesScope`, không import `lib/data/`.

## File đã sửa

- `lib/ui/components/steady_icon.dart`: thêm `SteadyIcons.check = 'check'` ở cuối danh sách (`assets/icons/check.svg` đã có, không thêm svg).
- `lib/features/placeholder/placeholder_screen.dart`: thêm tham số tuỳ chọn `Widget? action`. Có `action` thì thêm `SizedBox(height: s6)` và `action` ngay dưới `placeholderBody`, trong cùng `Column`. Không đổi gì khác.
- `lib/features/shell/home_shell.dart`: thêm `_openPaywall()` (push `MaterialPageRoute<void>` tới `PaywallScreen`), tab Focus truyền `action: SteadyButton(label: l10n.seePremium, onPressed: _openPaywall)` (variant và cỡ mặc định, không `block`), thêm hai dòng import (`steady_button.dart`, `premium/paywall_screen.dart`). Không sửa `PopScope`, `AnnotatedRegion` hay phần nào khác. Lưu ý: `dart format` đã tự đổi dáng viết của `_openPaywall` thành `Navigator.of(context)\n.push(MaterialPageRoute<void>(...))` (một câu lệnh, nội dung đúng như kế hoạch).
- `lib/l10n/app_en.arb`: thêm 17 khoá của mục 3.6 vào cuối file (nguyên văn), kèm `@paywallTermsMonthly` và `@paywallTermsWeekly` với placeholder `price` kiểu `String` theo mẫu `@spentLastMonth`. Nút X dùng khoá `close` đã có.
- `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`: sinh lại bằng `flutter gen-l10n`, không sửa tay.

## Lệnh đã chạy (từ gốc repo, `PUB_CACHE=C:\Users\nhatg\.local\pub-cache`)

- `flutter gen-l10n`: chạy, sinh lại hai file l10n; có hai khoá mới trong cả hai file.
- `dart format --output=none --set-exit-if-changed lib test`: lần đầu báo 2 file lệch (`paywall_screen.dart`, `home_shell.dart`), đã `dart format` riêng hai file đó. Chạy lại: 120 file, 0 thay đổi, exit 0.
- `flutter analyze`: lần đầu có 1 info (`use_null_aware_elements` ở `plan_option.dart`, do `if (note != null) note`), đã đổi thành `?note`. Chạy lại: "No issues found!", exit 0.
- `flutter test` (toàn bộ): 1244/1244 qua, exit 0 (khoảng 3 phút), sau khi đã sửa xong mọi thứ ở trên.
- Smoke test tạm (không thuộc bàn giao): viết một file test tạm đặt ở `.bangiao/` (không đặt trong `test/`), chạy bằng `flutter test` với cả phông Ahem mặc định và phông thật (nạp bằng `loadRealFonts`), rồi đã xoá file. Kiểm: 360x800 ở cỡ chữ 1.0 và 2.0, 360x560 ở 1.0 và 2.0, 320x640 ở 2.0; mở paywall từ "See Premium", hai giá và hai kỳ, đổi gói và dòng điều khoản đổi theo, bấm lại gói đang chọn, bấm nút chính hai lần ra đúng một dòng báo và màn không đóng, đổi gói sau đó dòng báo còn, đúng một nút `primary`, thẻ cao ít nhất 48, X đóng, Back đóng paywall mà app chưa thoát, Back lần nữa thì thoát, điểm (180, 500) vẫn là màu nền ở 360x800. Kết quả: với phông thật cả 5 kịch bản qua, không ném lỗi nào. Với phông Ahem, các kịch bản trong phạm vi mục 4 (360x800 ở 1.0 và 2.0, 360x560 ở 1.0) qua. Chỉ hai kịch bản vượt phạm vi kế hoạch bị lỗi tràn, và chỉ với Ahem: 360x560 ở cỡ chữ 2.0 (nút "See Premium" của tab Focus bị thanh tab che nên không chạm được) và 320x640 ở 2.0 (tab Focus tràn 4 px đáy; trên paywall, hàng của `PlanOption` tràn 17 px bên phải vì thẻ chỉ rộng 280).

## Lệnh chưa chạy

- Không có lệnh nào trong bộ kiểm CI bị bỏ qua.
- `graphify update .` (CLAUDE.md của repo nhắc) không chạy được: máy không có lệnh `graphify` và chưa có thư mục `graphify-out/`.
- Chưa mở bản xem trước web ở `http://localhost:5317` để nhìn tận mắt (không có trình duyệt trong phiên này); chỉ kiểm bằng widget test.

## Chỗ Tester nên soi kỹ

1. Chuỗi thẻ với phông Ahem của `flutter test`: kế hoạch yêu cầu `PlanOption` không tràn ở bề rộng 320, cỡ chữ 2.0, với đúng chuỗi của paywall. Tính tay: cột giá ("per month", caption 24 px, mỗi ký tự rộng 1 em) khoảng 217 px, cộng radio 24 và hai khoảng 12 là khoảng 265 px, còn trong 288 px (320 trừ đệm 32), nên vừa khít. Cột chữ bên trái chỉ còn khoảng 23 px nên tên gói bị bẻ từng ký tự (kế hoạch cho phép tên gói xuống dòng). Nếu thử paywall (không phải component riêng) ở máy 320 rộng và cỡ chữ 2.0 với Ahem thì sẽ tràn phải 17 px; kế hoạch chỉ đòi paywall ở 360, nên tôi không xử lý.
2. Phông Ahem làm paywall cao hơn 800 ngay ở cỡ chữ 1.0: phải `ensureVisible` rồi `pump` trước khi chạm thẻ gói, nút chính và nút X (chạm ngay sau `ensureVisible` mà không `pump` sẽ hụt). `tapScrolled` trong `test/helpers/money_helpers.dart` làm đúng việc này.
3. Mục 4, số 12: chữ "Focus" vẫn đúng hai lần, dòng "This part of Steady isn't ready yet." còn nguyên, điểm (180, 500) ở 360x800 cỡ chữ 1.0 vẫn là màu nền (đã tự kiểm qua), Back ở tab Focus khi không mở paywall vẫn thoát app. Test `shell_navigation_test.dart` và `layout_test.dart` hiện có đều qua.
4. Back sau khi mở paywall: `PopScope` của `HomeShell` có `canPop: _index == 0`, ở tab Focus nên `canPop` là `true` và Back chỉ đóng route paywall (đã kiểm).
5. Nhãn semantics: nhóm thẻ có nhãn "Choose a plan" (`Semantics(container: true, ...)`); nút X nhãn "Close" lấy từ `close`; mỗi thẻ là nút trong nhóm chọn một, `excludeSemantics: true`.
6. Locale: `MoneyFormat(formatLocaleOf(context), 'USD')`. Máy `en_US` ra `$9.99` và `$4.99`; máy `de_DE` quay về tag `en` nên vẫn ra `$` như cũ; các máy tiếng Anh vùng khác theo kết quả của `MoneyFormat`. Tôi chưa tự chạy trường hợp `de_DE` và máy tiếng Anh vùng khác.
7. Test sẵn có `test/static_rules_test.dart` và `test/design/assets_and_copy_test.dart` đều qua: không `Text('chữ cứng')` ngoài `lib/l10n/`, không `Color(0x` ngoài tokens, số svg vẫn 67, `SteadyIcons.check` có file `check.svg`.
8. Cờ "đã bấm nút chính" chỉ có đường bật: dòng báo ở lại khi đổi gói và khi bấm lại nhiều lần vẫn chỉ có một dòng; nút không ghi DB hay prefs và không đóng màn.

## Chỗ làm khác kế hoạch

Không có chỗ nào khác về hành vi hay cấu trúc. Hai chi tiết nhỏ ghi cho rõ: (a) nhãn semantics của `PlanOption` viết bằng `[title, price, period, ?note].join(', ')` vì lint `use_null_aware_elements` của repo (info làm rớt CI) bắt buộc dùng `?note` thay cho `if (note != null) note`; (b) `dart format` tự định dạng lại thân `_openPaywall` như đã nêu ở trên.
