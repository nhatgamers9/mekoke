# Kế hoạch: màn paywall xem thử, Monthly $9.99 và Weekly $4.99 (Steady)

Gốc repo: `D:\New folder\mekoke\mekoke`. Mọi đường dẫn dưới đây tính từ gốc repo.

Yêu cầu vòng này: "1A 2A 3A 4A", là câu trả lời cho bốn câu hỏi của vòng trước (yêu cầu gốc: "cho giá tuần là 4.99 và gói tháng là 9.99"). Đã chốt:

- Dựng màn paywall trong app để xem và bấm thử, chưa thu tiền. Hai gói: Monthly 9.99 mỗi tháng, Weekly 4.99 mỗi tuần. Bấm nút mua thì hiện dòng báo chưa mua được. Giá ghi cứng trong app.
- Tiền là đô la Mỹ: máy `en_US` hiện `$9.99` và `$4.99`.
- Mở paywall bằng nút chữ "See Premium" trên tab Focus.
- Cả hai gói dùng thử 3 ngày: thẻ gói ghi "3-day free trial", nút ghi "Try 3 days free".
- Bố cục theo `design/mockups/steady/Paywall.dc.html`, dựng trên giao diện Steady tối đang có trong `lib/` (token và component sẵn có). Monthly ở trên và được chọn sẵn, Weekly ở dưới, không nhãn (badge). Tiêu đề và bốn dòng lợi ích chép nguyên văn mockup.

## 1. Phạm vi

Không làm ở vòng này: mua thật, trạng thái Premium, khoá tính năng, "Restore purchase", link Terms và Privacy, sheet mở khoá, màn giới thiệu, đăng nhập và đăng ký. Không thêm gói thanh toán nào vào `pubspec.yaml`. Paywall chỉ có đúng các phần tử ở mục 3.4, không thêm phần tử nào khác của mockup hay hệ thiết kế.

Không đụng: `pubspec.yaml`, `android/`, `lib/main.dart`, `lib/core/`, `lib/data/`, `assets/`, `design/`, `README.md`, `web/`, `tool/`, `.gitignore`, `.metadata`, `analysis_options.yaml`. Cây làm việc đang có thay đổi chưa commit của việc khác ("bản xem trước trên web") ở `lib/data/database.dart`, `lib/main.dart`, `test/static_rules_test.dart`, `README.md`, `.gitignore`, `.metadata`, `analysis_options.yaml`, `web/`, `tool/`: không sửa, không hoàn tác.

## 2. Môi trường và lệnh

Phần này do phiên điều phối cung cấp; phiên lập kế hoạch không có shell nên chưa tự chạy.

- Flutter 3.47.6 không có trên PATH. Gọi bằng đường dẫn đầy đủ: `C:\Users\nhatg\.local\flutter\bin\flutter.bat` và `C:\Users\nhatg\.local\flutter\bin\dart.bat`.
- Trước mỗi lệnh phải đặt `PUB_CACHE=C:\Users\nhatg\.local\pub-cache` và đứng ở gốc repo (đường dẫn có dấu cách, nhớ đặt trong dấu nháy).
  - PowerShell: `$env:PUB_CACHE='C:\Users\nhatg\.local\pub-cache'; Set-Location 'D:\New folder\mekoke\mekoke'; & 'C:\Users\nhatg\.local\flutter\bin\flutter.bat' analyze`
  - Bash: `cd "/d/New folder/mekoke/mekoke" && PUB_CACHE='C:\Users\nhatg\.local\pub-cache' "/c/Users/nhatg/.local/flutter/bin/flutter.bat" analyze`
- Bộ kiểm của CI (`.github/workflows/build-apk.yml`), phải qua cả ba trước khi xong:
  1. `dart format --output=none --set-exit-if-changed lib test`
  2. `flutter analyze` (mức info cũng làm rớt)
  3. `flutter test` (hiện 1244/1244 qua, chạy hết khoảng 4 đến 5 phút)
- Sau khi sửa `lib/l10n/app_en.arb` phải chạy `flutter gen-l10n` để sinh lại `lib/l10n/app_localizations.dart` và `lib/l10n/app_localizations_en.dart`. Không sửa tay hai file sinh ra. Nếu bước 1 báo hai file này lệch định dạng thì chạy `dart format lib/l10n`.
- Một bản xem trước web đang chạy ở `http://localhost:5317`, tự hot reload khi file trong `lib/` đổi. Không tắt, không khởi động lại nó. Không chạy `flutter run`. Tuyệt đối không chạy `flutter create`.

## 3. Việc của Coder

Coder không tạo và không sửa file nào trong `test/`. Test mới do Tester viết (mục 6). Test hiện có rớt thì sửa mã trong `lib/`, không sửa test.

### 3.1 File

Tạo:

| File | Nội dung |
|---|---|
| `lib/features/premium/premium_plans.dart` | Dữ liệu hai gói, nơi duy nhất ghi hai mức giá. |
| `lib/ui/components/plan_option.dart` | Component `PlanOption`. |
| `lib/features/premium/paywall_screen.dart` | Màn paywall. |

Sửa:

| File | Việc |
|---|---|
| `lib/ui/components/steady_icon.dart` | Thêm `static const check = 'check';` vào cuối danh sách hằng của `SteadyIcons` (file `assets/icons/check.svg` đã có). |
| `lib/features/placeholder/placeholder_screen.dart` | Thêm tham số tuỳ chọn `action` (mục 3.5). |
| `lib/features/shell/home_shell.dart` | Thêm `_openPaywall()` và truyền nút vào `PlaceholderScreen` (mục 3.5). |
| `lib/l10n/app_en.arb` | Thêm các khoá ở mục 3.6 vào cuối file, rồi chạy `flutter gen-l10n`. |

### 3.2 `lib/features/premium/premium_plans.dart`

File thuần Dart, không import Flutter.

```dart
enum PlanPeriod { monthly, weekly }

class PremiumPlan {
  const PremiumPlan({required this.period, required this.priceMinor});
  final PlanPeriod period;
  final int priceMinor; // đơn vị nhỏ nhất của kPlanCurrency: 999 là 9.99
}

const String kPlanCurrency = 'USD'; // mã ISO 4217

// Thứ tự hiển thị; phần tử đầu được chọn sẵn.
const List<PremiumPlan> kPremiumPlans = [
  PremiumPlan(period: PlanPeriod.monthly, priceMinor: 999),
  PremiumPlan(period: PlanPeriod.weekly, priceMinor: 499),
];
```

Chú thích đầu file (tiếng Việt, như các file khác trong `lib/`): đây là giá tạm để hiển thị; khi nối cửa hàng thì thay bằng giá cửa hàng trả về.

### 3.3 `lib/ui/components/plan_option.dart`

```dart
class PlanOption extends StatelessWidget {
  const PlanOption({
    super.key,
    required this.title,
    required this.price, // đã định dạng; component không tự định dạng
    required this.period,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final VoidCallback onTap;
  final String? note;
}
```

- Thẻ: `Material(color: surface, shape: RoundedRectangleBorder(bo SteadyRadius.lg, BorderSide rộng 2 màu lineStrong; khi chọn màu amber))` bọc `InkWell(onTap, customBorder: cùng shape)`, bên trong đệm `SteadySpace.s4` mọi phía. Cả thẻ bấm được. Cao tối thiểu `SteadySize.tap`.
- Nội dung là `Row` canh giữa theo chiều dọc: ô radio, `SizedBox(width: s3)`, `Expanded(cột chữ)`, `SizedBox(width: s3)`, cột giá.
- Ô radio: tròn 24×24, viền 2 màu `lineStrong`, không nền. Khi chọn: nền và viền `amber`, bên trong là `SteadyIcon(SteadyIcons.check, size: 16, color: onAmber)`. Chưa chọn thì không có icon.
- Cột chữ, canh trái: `title` kiểu `SteadyText.headline` màu `ink`; nếu có `note` thì cách 2 px rồi `note` kiểu `label` màu `inkMuted`. Không đặt `maxLines`, không ellipsis: chữ dài thì xuống dòng.
- Cột giá, canh phải, rộng theo nội dung (không `Expanded`, không `Flexible`): `price` kiểu `bodyStrong` màu `ink`; dưới là `period` kiểu `caption` màu `inkMuted`. Mỗi dòng `maxLines: 1`, không ellipsis.
- Semantics bọc ngoài cùng, chép `lib/ui/components/icon_tile.dart`: `button: true`, `selected: selected`, `inMutuallyExclusiveGroup: true`, `onTap: onTap`, `excludeSemantics: true`, `label` là `title`, `price`, `period`, rồi `note` (nếu có), nối bằng `', '`.
- Không dùng `LayoutBuilder` trong component này (mục 4, số 10).
- Không thêm tham số `badge` của hệ thiết kế: vòng này không màn nào dùng.

### 3.4 `lib/features/premium/paywall_screen.dart`

```dart
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
}
```

Trạng thái: gói đang chọn (kiểu `PlanPeriod`, ban đầu `kPremiumPlans.first.period`) và một cờ `bool` "đã bấm nút chính" (ban đầu `false`; chỉ có đường bật, không có đường tắt). Màn không gọi `ServicesScope` và không import gì từ `lib/data/`.

Cây widget: `Scaffold` > `SafeArea` > `CustomScrollView` > `SliverFillRemaining(hasScrollBody: false)` > `Padding(EdgeInsets.fromLTRB(s5, s3, s5, s6))` > `Column(crossAxisAlignment: stretch)`, gồm lần lượt:

1. Canh phải: `SteadyIconButton(variant: SteadyIconButtonVariant.plain, icon: SteadyIcons.x, semanticLabel: l10n.close, onPressed: () => Navigator.of(context).maybePop())`.
2. Cách `s5`. `l10n.paywallOverline` kiểu `overline` màu `amber`; cách `s2`; `l10n.paywallTitle` kiểu `display` màu `ink`.
3. Cách `s5`. Bốn hàng lợi ích theo thứ tự `paywallBenefitSounds`, `paywallBenefitStreaks`, `paywallBenefitPlans`, `paywallBenefitHistory`, cách nhau `s3`. Mỗi hàng: `SteadyIcon(SteadyIcons.check, size: 20, color: tide)`, `SizedBox(width: s3)`, `Expanded(Text)` kiểu `body` màu `ink`.
4. `Spacer()`, rồi `SizedBox(height: s5)`.
5. `Semantics(container: true, label: l10n.choosePlanLabel)` bọc một cột gồm một `PlanOption` cho mỗi phần tử của `kPremiumPlans`, đúng thứ tự của danh sách, cách nhau `s3`:
   - `title`: `planMonthly` hoặc `planWeekly`.
   - `price`: `MoneyFormat(formatLocaleOf(context), kPlanCurrency).format(plan.priceMinor)`.
   - `period`: `planPerMonth` hoặc `planPerWeek`.
   - `note`: `planTrialNote` (cả hai gói).
   - `selected`: gói này là gói đang chọn. `onTap`: đặt gói đang chọn thành gói này.
6. Cách `s5`. Nếu cờ đã bật: `SteadyInlineStatus(message: l10n.paywallUnavailable)` (tone mặc định) rồi cách `s3`.
7. `SteadyButton(variant: SteadyButtonVariant.primary, block: true, label: l10n.paywallCta, onPressed: bật cờ)`. Nút chỉ bật cờ, không làm gì khác.
8. Cách `s5`. Dòng điều khoản của gói đang chọn: `l10n.paywallTermsMonthly(price)` hoặc `l10n.paywallTermsWeekly(price)`, với `price` là chuỗi giá đã định dạng của gói đó; kiểu `caption` màu `inkMuted`, `textAlign: TextAlign.center`.

Chọn chuỗi theo `PlanPeriod` bằng `switch` đủ nhánh (mẫu: `_moodLabel` trong `lib/ui/components/mood_picker.dart`).

### 3.5 Lối vào trên tab Focus

`lib/features/placeholder/placeholder_screen.dart`:

```dart
const PlaceholderScreen({super.key, required this.title, this.action});

final String title;
final Widget? action;
```

Có `action` thì thêm `SizedBox(height: SteadySpace.s6)` và `action` ngay dưới dòng `placeholderBody`, trong cùng `Column` (giữ `crossAxisAlignment: start`). Không canh giữa, không dồn xuống đáy. Không đổi gì khác của màn này.

`lib/features/shell/home_shell.dart`, trong `_HomeShellState`:

```dart
void _openPaywall() {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
  );
}
```

Dòng 61 đổi thành:

```dart
PlaceholderScreen(
  title: l10n.tabFocus,
  action: SteadyButton(label: l10n.seePremium, onPressed: _openPaywall),
),
```

Giữ `variant` mặc định của `SteadyButton` (`secondary`), cỡ mặc định, không `block`. Không sửa `PopScope`, `AnnotatedRegion` hay phần nào khác của file.

### 3.6 Câu chữ (thêm vào cuối `lib/l10n/app_en.arb`)

| Khoá | Nguyên văn |
|---|---|
| `seePremium` | See Premium |
| `paywallOverline` | STEADY PREMIUM |
| `paywallTitle` | Every sound, every plan, no ads |
| `paywallBenefitSounds` | Every sound, offline |
| `paywallBenefitStreaks` | Unlimited habit streaks |
| `paywallBenefitPlans` | Custom fasting and interval plans |
| `paywallBenefitHistory` | Full history and widget themes |
| `choosePlanLabel` | Choose a plan |
| `planMonthly` | Monthly |
| `planWeekly` | Weekly |
| `planPerMonth` | per month |
| `planPerWeek` | per week |
| `planTrialNote` | 3-day free trial |
| `paywallCta` | Try 3 days free |
| `paywallUnavailable` | Purchases aren't available yet. |
| `paywallTermsMonthly` | Free for 3 days, then {price} per month. Cancel anytime in Google Play. |
| `paywallTermsWeekly` | Free for 3 days, then {price} per week. Cancel anytime in Google Play. |

`{price}` là placeholder kiểu `String`, khai bằng khoá `@paywallTermsMonthly` và `@paywallTermsWeekly` theo mẫu `@spentLastMonth` trong cùng file. Nút X dùng khoá `close` đã có.

## 4. Trường hợp biên bắt buộc

1. Cỡ chữ hệ thống 2.0 ở 360×800: tab Focus và paywall không ném lỗi tràn; paywall cuộn được tới nút chính và dòng điều khoản; giá hiện đủ trong thẻ. Tên gói được phép xuống dòng.
2. Màn thấp (360×560): paywall cuộn được, không tràn.
3. Luôn có đúng một gói được chọn. Bấm lại gói đang chọn không bỏ chọn. Đổi gói thì dòng điều khoản đổi theo giá và kỳ của gói đó.
4. Nút chính chỉ làm hiện `paywallUnavailable`: không ghi DB, không ghi `prefs`, không đóng màn, không đổi trạng thái nào khác. Bấm nhiều lần vẫn chỉ có một dòng. Đổi gói sau đó thì dòng báo vẫn còn.
5. Nút X và nút Back của Android đóng paywall, về tab Focus, app chưa thoát; Back lần nữa mới thoát.
6. Paywall chỉ mở khi người dùng tự bấm "See Premium". Không tự bật lúc mở app, lúc đang nhịn ăn hay đang chạy bài tập.
7. Giá chỉ đi qua `MoneyFormat`, không nối ký hiệu tiền bằng tay. Máy `en_US` ra đúng `$9.99` và `$4.99`. Máy không phải tiếng Anh (ví dụ `de_DE`) vẫn ra `$9.99` và `$4.99` như phần còn lại của app. Máy tiếng Anh vùng khác thì theo đúng kết quả của `MoneyFormat` cho vùng đó. Không locale nào làm crash.
8. Đọc màn hình: mỗi thẻ gói là nút trong nhóm chọn một, có hành động chạm, đọc được tên, giá, kỳ, dòng dùng thử và trạng thái chọn; nhóm thẻ có nhãn "Choose a plan"; nút X có nhãn "Close"; dòng báo ở bước 6 được đọc khi hiện (`SteadyInlineStatus` đã là `liveRegion`).
9. Thẻ gói cao tối thiểu `SteadySize.tap`.
10. Không đặt `LayoutBuilder` ở bất kỳ đâu bên trong `SliverFillRemaining(hasScrollBody: false)`, kể cả trong `PlanOption`: sliver này đo chiều cao nội tại nên `LayoutBuilder` sẽ ném lỗi.
11. Cả paywall có đúng một nút `primary`.
12. Tab Focus sau khi thêm nút: vẫn còn dòng "This part of Steady isn't ready yet."; chữ "Focus" vẫn chỉ xuất hiện đúng hai lần; điểm (180, 500) ở 360×800 vẫn là màu nền (nút nằm ngay dưới dòng chữ, phía trên toạ độ này); Back ở tab Focus khi không mở paywall vẫn thoát app.

## 5. Quy ước và file mẫu

| Việc | Chép quy ước từ |
|---|---|
| Màn toàn trang có nút X, mở bằng `MaterialPageRoute<void>` | `lib/features/money/entry_editor_screen.dart`, `lib/features/money/money_screen.dart` (`_openEditor`) |
| Thân cuộn có `Spacer`, nội dung dài thì cuộn | `lib/features/timer/interval_run_screen.dart` (`SliverFillRemaining(hasScrollBody: false)`) |
| Định dạng tiền và lấy locale | `lib/features/money/money_screen.dart` (`MoneyFormat(formatLocaleOf(context), ...)`) |
| Thẻ chọn một có viền 2 px đổi sang `amber` khi chọn (`Material` + `shape` + `InkWell`) | `lib/ui/components/mood_picker.dart` (`_MoodItem`) |
| Semantics của ô chọn một | `lib/ui/components/icon_tile.dart` |
| Màu từ `SteadyColors.of(context)`, chữ từ `SteadyText`, khoảng cách từ `SteadySpace` | `lib/ui/components/steady_chip.dart` |
| Dòng báo tại chỗ nằm trên nút chính | `lib/features/money/entry_editor_screen.dart` (`_error`) |
| Nhóm có nhãn (`Semantics(container: true, label: ...)`) | `lib/features/money/entry_editor_screen.dart` (`l10n.categoryLabel`) |
| Dữ liệu thuần tách file riêng | `lib/features/streaks/habit_name.dart` |
| Khoá ARB có tham số | `lib/l10n/app_en.arb` (`spentLastMonth`) |
| Thứ tự import, chú thích tiếng Việt | `lib/features/shell/home_shell.dart`, `lib/ui/components/icon_tile.dart` |

## 6. Test mới (việc của Tester)

File:

| File | Việc |
|---|---|
| `test/features/premium_plans_test.dart` (tạo) | Test dữ liệu gói. |
| `test/ui/plan_option_test.dart` (tạo) | Test component. |
| `test/widget/paywall_test.dart` (tạo) | Test màn và lối vào. |
| `test/design/assets_and_copy_test.dart` (sửa) | Chỉ thêm một nhóm test câu chữ paywall; không sửa test đang có. |

Phải phủ:

- `kPremiumPlans`: đúng hai phần tử, thứ tự monthly rồi weekly, giá 999 và 499; `kPlanCurrency` là `'USD'`.
- `PlanOption`: màu viền theo `selected`; ô radio (có và không có dấu tích); Semantics (mục 4, số 8); chạm bất kỳ đâu trên thẻ gọi `onTap`; cao tối thiểu 48; có và không có `note`; không tràn ở bề rộng 320, cỡ chữ 2.0, với đúng các chuỗi của paywall.
- Paywall: mở từ nút "See Premium" trên tab Focus; hai giá và hai kỳ hiện đúng; Monthly chọn sẵn; đổi gói đổi dòng điều khoản; bấm lại gói đang chọn; bấm nút chính (một lần và nhiều lần) hiện đúng một dòng báo và màn không đóng; X và Back; mục 4 số 1, 2, 7, 11, 12.
- Nguyên văn mọi khoá ở mục 3.6, và `SteadyIcons.check == 'check'`.

Mẫu để chép:

| Việc | File |
|---|---|
| Test component (`_host`, `_size`, Semantics, cỡ chữ 2.0) | `test/ui/money_components_test.dart` (nhóm `IconTile`) |
| Dựng và gỡ app (`pumpSteadyApp`, `disposeSteadyApp`) | `test/helpers/test_app.dart` |
| `tapTab`, `settle`, `captureSystemPop`, `pixelAt`, `FakeNow`, `evening` | `test/helpers/widget_helpers.dart` |
| Back của Android, thoát app | `test/widget/shell_navigation_test.dart` |
| Locale của máy | `test/widget/locale_test.dart` |
| Tràn ở cỡ chữ 2.0 | `test/widget/layout_test.dart` |
| Câu chữ tiếng Anh | `test/design/assets_and_copy_test.dart` |
| Cuộn tới rồi mới chạm (`tapScrolled`) | `test/helpers/money_helpers.dart` |

Lưu ý: `flutter test` dùng phông thử có mỗi ký tự rộng 1 em, nên theo ước tính paywall dài hơn 800 ngay ở cỡ chữ 1.0. Gọi `ensureVisible` trước khi chạm thẻ gói hoặc nút chính.

## 7. Test hiện có dễ rớt

| Test | Rớt khi |
|---|---|
| `test/static_rules_test.dart` | `lib/` có `Text('chữ cứng')` ngoài `lib/l10n/`; có `Color(0x` ngoài `lib/core/theme/tokens.dart`; có chuỗi `DateTime.now()` (kể cả trong chú thích). |
| `test/design/assets_and_copy_test.dart` | Thêm file `.svg` vào `assets/icons/` (phải giữ đúng 67); khai hằng trong `SteadyIcons` mà không có file cùng tên; `pubspec.yaml` chứa `riverpod`, `provider:`, `get_it`, `google_fonts`. |
| `test/widget/shell_navigation_test.dart` | Vi phạm mục 4, số 12. |
| `test/widget/layout_test.dart` | Tab Focus tràn ở cỡ chữ 2.0. |
| `test/design/token_sync_test.dart` | Sửa `lib/core/theme/tokens.dart`, `lib/core/theme/typography.dart` hoặc `design/steady-ds/`. Vòng này không sửa các file đó. |

Coder và Tester không tự nới các phép kiểm trên.
