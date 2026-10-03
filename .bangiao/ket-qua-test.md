# Kết quả kiểm thử: màn paywall xem thử, Monthly $9.99 và Weekly $4.99 (Steady)

Kết luận: XANH HẾT. Không có test nào rớt ở bản cuối; không phát hiện lỗi của mã sản phẩm. Tester không sửa gì trong `lib/` và không đụng các file của việc khác trong cây làm việc.

## File test đã tạo hoặc sửa (chỉ trong `test/`)

| File | Việc | Số test |
|---|---|---|
| `test/features/premium_plans_test.dart` (tạo) | Dữ liệu gói: đúng hai phần tử, thứ tự monthly rồi weekly, giá 999 và 499, `kPlanCurrency == 'USD'`, giá qua `MoneyFormat` ra `$9.99` và `$4.99` | 8 |
| `test/ui/plan_option_test.dart` (tạo) | Component `PlanOption`: màu viền theo `selected`, ô radio có và không có dấu tích, Semantics, chạm bất kỳ đâu gọi `onTap`, cao tối thiểu 48, có và không có `note`, không tràn ở 320 và 360 với cỡ chữ 1.0 và 2.0 bằng đúng chuỗi của paywall, chạy được trong `SliverFillRemaining(hasScrollBody: false)` | 31 |
| `test/widget/paywall_test.dart` (tạo) | Màn và lối vào (phông Ahem mặc định) | 67 |
| `test/widget/paywall_fit_test.dart` (tạo, ngoài danh sách mục 6 của kế hoạch) | Bố cục tab Focus + paywall với phông thật (Figtree, Newsreader), theo mẫu `money_editor_fit_test.dart` | 8 |
| `test/design/assets_and_copy_test.dart` (sửa) | Chỉ thêm một nhóm cuối file `paywall copy (section 3.6 of the plan)`; không sửa test đang có | 6 mới (file này giờ có 39) |

Tổng test mới: 120.

## Phủ theo kế hoạch

- Đường chạy thuận lợi: mở paywall từ "See Premium"; hai giá và hai kỳ đúng; Monthly chọn sẵn; đổi gói đổi dòng điều khoản (hai chiều); X đóng; Back đóng paywall rồi Back lần nữa mới thoát app; nguyên văn mọi khoá mục 3.6; `SteadyIcons.check == 'check'` có file `check.svg`.
- Trường hợp biên đã nêu tên trong kế hoạch (mục 4):
  - Số 1: cỡ chữ 2.0 ở 360x800, tab Focus và paywall không tràn, cuộn tới nút chính và dòng điều khoản, giá nằm trọn trong thẻ.
  - Số 2: 360x560 ở cỡ chữ 1.0 và 2.0, paywall cuộn được, không tràn.
  - Số 3: luôn đúng một gói chọn sau mỗi lần bấm; bấm lại gói đang chọn không bỏ chọn.
  - Số 4: nút chính chỉ hiện đúng một dòng báo (một lần, năm lần, sau khi đổi gói dòng vẫn còn), màn không đóng, không ghi DB hay prefs (so ảnh chụp mọi bảng trước và sau), dòng báo nằm trên nút.
  - Số 5: X và Back; Back sau khi bấm nút chính vẫn chỉ đóng paywall.
  - Số 6: không tự mở lúc khởi động, khi đi qua từng tab, khi đang nhịn ăn, khi đang chạy bài Interval.
  - Số 7: máy `en_US` ra `$9.99` và `$4.99`; máy `de_DE` vẫn ra `$`; `en_GB`, `en_AU`, `en_CA`, `en_IN`, `en_ZA` ra đúng kết quả của `MoneyFormat` cho vùng đó; 14 locale khác (ja_JP, vi_VN, ar_EG, fr_FR, es_MX, pt_BR, hi_IN, ru_RU, tr_TR, he_IL, th_TH, zh_Hant_TW, en, xx_YY) không crash và vẫn ra hai giá.
  - Số 8: mỗi thẻ là nút trong nhóm chọn một, có hành động chạm, nhãn `Monthly, $9.99, per month, 3-day free trial`, trạng thái chọn đổi theo; nhóm có nhãn "Choose a plan"; X có nhãn "Close"; dòng báo là `liveRegion`; hành động chạm qua semantics chọn được gói.
  - Số 9: thẻ cao tối thiểu 48 ở cỡ chữ 1.0 và 2.0.
  - Số 10: không `LayoutBuilder` trong `SliverFillRemaining`: kiểm bằng hành vi (mở paywall và `PlanOption` trong sliver đó, không ném lỗi).
  - Số 11: đúng một nút `primary` trên paywall, trước và sau khi bấm nút chính.
  - Số 12: tab Focus còn dòng "This part of Steady isn't ready yet.", chữ "Focus" đúng hai lần, điểm (180, 500) ở 360x800 vẫn là màu nền, nút nằm dưới dòng chữ và trên y=500, Back ở Focus khi không mở paywall vẫn thoát app.
- Trường hợp phải thất bại (đường lỗi): bấm nút chính thì được báo "Purchases aren't available yet." và không có gì được mua hay ghi; chạm ngoài thẻ không gọi `onTap`.
- Thêm ngoài danh sách: mở lại paywall thì bắt đầu mới (Monthly, không có dòng báo); không có nhãn (badge) nào trên hai gói; X cao rộng ít nhất 48.

## Lệnh đã chạy (từ gốc repo, `PUB_CACHE=C:\Users\nhatg\.local\pub-cache`)

| Lệnh | Kết quả |
|---|---|
| `flutter test` từng file mới/sửa | premium_plans 8/8, plan_option 31/31, paywall_test 67/67, paywall_fit_test 8/8, assets_and_copy_test 39/39; không rớt |
| `dart format --output=none --set-exit-if-changed lib test` | 124 file, 0 thay đổi, exit 0 |
| `flutter analyze` | "No issues found!", exit 0 |
| `flutter test` (cả bộ) | 1364/1364 qua, 0 rớt, exit 0 (khoảng 3 phút 9 giây). Trước là 1244, cộng 120 test mới |

Không có test rớt ở bản cuối, nên không có phần rớt để chép.

## Lần chạy đầu của các test mới (ghi cho trung thực)

Lần chạy đầu có 5 test rớt trong `plan_option_test.dart` và 5 trong `paywall_test.dart`. 9 trong 10 là lỗi viết test của tôi, không phải lỗi mã sản phẩm, đã sửa test; con còn lại (360x560 cỡ chữ 2.0) lộ ra quan sát số 1 bên dưới. Chi tiết:

- Chạm cách góc thẻ 3 px không gọi `onTap`: vì `InkWell` có `customBorder` bo 22 px nên góc đó nằm ngoài hình thẻ (đúng ý thiết kế). Đổi sang chạm cách góc 8 px.
- Hai thẻ ở cỡ chữ 2.0 với Ahem cao hơn 800 trong khung chiều cao bị chặn nên báo `RenderFlex overflowed`: đổi khung thử sang cuộn được, như thân cuộn thật của paywall.
- Sau khi `tapScrolled` nút chính, paywall đã cuộn xuống nên nút X nằm ngoài khung nhìn: thêm bước cuộn lên rồi mới bấm X.
- Tìm thanh tab khi paywall đang phủ: thanh tab thuộc route bên dưới nên `find` mặc định bỏ qua; dùng `skipOffstage: false`.
- `en_ZA` ra `$9,99` (dấu phẩy thập phân) chứ không phải `$9.99`: đó là kết quả của `MoneyFormat` cho vùng đó, đúng kế hoạch; đổi phép kiểm sang `9[.,]99`.

## Quan sát ngoài phạm vi kế hoạch (không phải test rớt)

1. Với phông Ahem của `flutter test`, tab Focus ở 360x560 và cỡ chữ 2.0 tràn 36 px ở đáy (thấy khi dựng cả app ở kích thước đó, trước khi mở paywall; phần tràn đến từ tab Focus có thêm nút "See Premium", không phải từ paywall). Kế hoạch chỉ đòi tab Focus không tràn ở 360x800 (mục 4, số 1) và paywall ở 360x560 (số 2), nên không có test bắt buộc cho tổ hợp này. Tôi đã kiểm riêng với phông thật (nạp bằng `loadRealFonts`): tab Focus và paywall không tràn ở 360x560, 360x640 và 320x480 với cỡ chữ 1.0, 1.3 và 2.0. Vì vậy chỉ ghi lại, không coi là lỗi. Hệ quả cho test: ở `paywall_test.dart`, phép đo paywall ở 360x560 cỡ chữ 2.0 dựng paywall đứng một mình (không có tab Focus bên dưới); tab Focus ở các kích thước này do `paywall_fit_test.dart` (phông thật) phủ.
2. Nút X nằm đầu thân cuộn (đúng mục 3.4), nên khi người dùng đã cuộn xuống nút chính thì phải cuộn lên mới thấy X; nút Back của Android vẫn đóng được từ mọi vị trí cuộn.
3. `InkWell` của `PlanOption` không nhận chạm ở bốn góc nằm ngoài đường bo của thẻ (hành vi mong muốn, không có test khoá hành vi này).

## Chưa làm

- Chưa mở bản xem trước web `http://localhost:5317` để nhìn tận mắt (không có trình duyệt trong phiên này); không động tới tiến trình đó.
- `graphify update .` không chạy (máy không có lệnh `graphify`), giống ghi chú của Coder.
- Không commit, không push.
