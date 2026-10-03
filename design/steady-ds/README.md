Steady là app offline giúp người dùng tập trung, ngủ, nhịn ăn gián đoạn, tập ngắt quãng và bỏ thói quen xấu. App có 5 tab: **Focus** (âm thanh nền), **Timer** (nhịn ăn và HIIT/Tabata), **Streaks** (đếm ngày "sạch"), **Money** (thu chi theo phong bì hoặc 50/30/20, hoàn toàn offline) và **Check-in** (tâm trạng buổi tối). "Steady" là tên tạm. Giao diện tiếng Anh (US) là gốc, sau đó dịch sang tiếng Tây Ban Nha, Đức, Pháp, Nhật. Tinh thần chung: yên tĩnh, ấm, không phán xét. Màn hình nào cũng phải dễ chịu khi mở lúc 2 giờ sáng.

## Giọng văn (UI copy)

- Viết tiếng Anh Mỹ, gọi người dùng là "you", viết hoa chữ đầu câu (sentence case) cho cả tiêu đề và nút. Câu ngắn, không dấu chấm than, không emoji.
- Nhãn nút bắt đầu bằng động từ: "Start fasting", "Save check-in", "Unlock for 24 hours", "Try 3 days free".
- Báo tình trạng bằng sự thật, không cổ vũ ồn ào: "Your fast ends at 12:00 PM." thay vì "You're crushing it!!".
- Không phán xét khi tái phạm: "That's okay. Day 1 starts now." Tránh các từ *failed*, *cheat*, *guilt*, *relapse* trên giao diện.
- Không tuyên bố tác dụng y khoa: không viết "burn fat", "cure insomnia", "treat ADHD". Viết "Sounds to help you focus" và "A timer for your eating window". Màn hình nhịn ăn có một dòng nhắc người dùng hỏi ý kiến bác sĩ.
- Định dạng giờ, ngày, giá theo locale của máy, không ghép chuỗi tay.

## Màu

- Có ba theme. **Dark** là mặc định và là theme đầu tiên. **Light** chỉ bật khi người dùng chọn Light hoặc "Match system" trong Settings. **Bedtime** là nền đen tuyệt đối với chữ ấm: dùng cho màn hình hẹn giờ ngủ và bất kỳ màn hình nào khi bật "Bedtime mode". Không có ánh xanh lam, để không làm người dùng tỉnh ngủ.
- Các lớp nền đi từ `bg` lên `surface` (thẻ, ô âm thanh, sheet) rồi `surface-2` (control, rãnh tiến độ). Tách lớp bằng độ sáng, không dùng bóng đổ. Chỉ bottom sheet mới có `shadow-sheet`.
- `amber` là màu nhấn duy nhất: nút chính, thứ đang chạy, tab đang mở, vòng nhịn ăn và hiệp WORK. Nếu một màn hình có hơn hai vùng amber lớn thì đang dùng quá tay.
- Chữ đặt trên nền amber dùng `on-amber`. Chữ amber đặt trên `bg`, `surface`, `surface-2` hoặc `amber-soft`.
- `tide` là nghỉ ngơi và hoàn thành: cửa sổ ăn, hiệp REST, mốc chuỗi đã đạt. Màu này lệch về xanh lam để người mù màu đỏ–lục vẫn phân biệt được với `amber` và `rose`.
- `rose` chỉ dành cho hai việc: hành động xoá dữ liệu, và trạng thái vượt ngân sách trong tab Money (luôn kèm icon `triangle-alert` và chữ "Over by …"). Đặt lại một chuỗi là hành động trung tính (`secondary`), không tô đỏ. Khoản chi bình thường cũng không tô đỏ.
- Màu không bao giờ là thông tin duy nhất: mỗi pha có nhãn chữ (FASTING, EATING, WORK, REST), mỗi chip tự nói rõ trạng thái của nó.
- Mọi cặp chữ/nền ghi trong usage note của token đều đạt ít nhất 4.5:1 ở cả ba theme. Viền control (`line-strong`), vòng tiến độ và viền focus đạt ít nhất 3:1.
- Không dùng gradient, không dùng ảnh nền.

## Chữ

- **Newsreader** (serif) cho con số và tiêu đề: `count-xl` cho số ngày chuỗi, `timer-xl` cho đồng hồ nhịn ăn và hẹn giờ ngủ, `display` cho tiêu đề màn hình, `title` cho tên âm thanh và tiêu đề sheet. Chữ số của Newsreader mặc định rộng đều nên đồng hồ không bị giật.
- **Figtree** (sans) cho mọi chữ giao diện: `headline`, `body`, `body-strong`, `label`, `caption`, `overline`.
- Đồng hồ HIIT/Tabata dùng `count-gym` (Figtree 800) vì người dùng nhìn nó từ xa giữa lúc tập. Số liệu phụ dùng `stat`. Cả hai bật `tabular-nums`.
- Tiền luôn dùng sans: `money-xl` cho số tiền chính của màn hình (chữ số tỉ lệ), `body-strong` với `tabular-nums` cho số tiền trong danh sách. Không dùng serif cho tiền.
- `overline` luôn viết HOA trong nội dung, chỉ dùng cho nhãn pha và nhãn nhóm.
- Ở bản tiếng Nhật, chữ rơi về font hệ thống (Noto Sans JP trên Android). Giữ nguyên cỡ chữ và chiều cao dòng.
- Hai file `.woff2` trong `fonts/` chỉ chứa bộ ký tự Latin, dùng cho bản xem trước. Trong app Flutter, dùng bản đầy đủ của Newsreader và Figtree tải từ Google Fonts (giấy phép OFL), đóng gói sẵn trong app để chạy offline.

## Khoảng cách, bo góc, kích thước

- Lưới 4px. Màn hình thiết kế ở 360dp. Lề trái/phải là `space-5`, khoảng giữa các khối là `space-6`, khoảng trên/dưới TimerRing là `space-8`.
- Nút và chip luôn bo tròn hết (`radius-full`). Thẻ, ô âm thanh, PlanOption dùng `radius-lg`. Góc trên của sheet và paywall dùng `radius-xl`. Ô nhập và ô MoodPicker dùng `radius-md`.
- Vùng chạm tối thiểu `size-tap` (48px). Nút lớn cao `size-button`, nút Play `size-play`, vòng đếm `size-ring` với nét `size-ring-stroke`.

## Trạng thái và chuyển động

- Focus bàn phím và TalkBack: `focus-ring` (khe màu nền rồi 2px amber). Disabled: độ mờ 40%. Pressed: hiệu ứng ripple mặc định của Flutter, màu `ink` ở 8%.
- Chuyển động chậm và êm: 150–250ms, ease-out, không nảy. Vòng đếm chạy mượt theo từng giây. Equalizer trên SoundTile đứng yên. Khi người dùng bật "Reduce motion" thì tắt hết chuyển động trang trí.
- Đang trong một phiên (phát âm thanh, nhịn ăn, HIIT, hẹn giờ ngủ) thì không hiện quảng cáo, popup đánh giá hay paywall.

## Biểu tượng

- Dùng bộ **Lucide** bản 1.49.0 (giấy phép ISC): nét 2px trên khung 24px, ăn theo màu chữ. Có 67 icon trong `assets/Icons/` và trong component `Icon`.
- Tab: `audio-waveform` Focus, `timer` Timer, `sprout` Streaks, `notebook-pen` Check-in. Âm thanh: `waves` brown noise, `wind` white noise, `leaf` pink noise, `cloud-rain` mưa to, `cloud-drizzle` mưa nhỏ, `cloud-lightning` sấm, `umbrella` mưa trên ô, `shell` biển, `trees` rừng, `droplets` suối, `flame` lửa, `bird` chim, `coffee` quán cà phê, `train-front` tàu, `car` xe, `fan` quạt, `music` nhạc cụ, `bell-ring` chuông thiền. Premium: `lock` và `lock-open`. Money: `wallet` (tab), `shopping-cart` đi chợ, `house` nhà ở, `zap` hoá đơn điện nước, `car` đi lại, `coffee` ăn uống ngoài, `shirt` mua sắm, `heart-pulse` sức khoẻ, `gift` quà, `plane` du lịch, `smartphone` điện thoại, `graduation-cap` học tập, `briefcase` lương, `banknote` tiền mặt, `credit-card` thẻ, `piggy-bank` tiết kiệm, `arrow-left-right` chuyển tiền, `triangle-alert` vượt ngân sách.
- Không dùng emoji ở bất kỳ đâu. Mặt cười của MoodPicker là SVG nét vẽ riêng, cùng độ dày nét với Lucide.
- Trong Flutter: render file SVG bằng `flutter_svg` và tô màu bằng `colorFilter` theo token.
- App chưa có logo. Tạm thời viết tên "Steady" bằng Newsreader 500. Biểu tượng app cần được thiết kế riêng.

## Các mẫu màn hình

- **Focus**: đầu tab là `FilterChips` theo nhóm (All, Rain, Nature, Noise, City, Meditation), bên dưới là thư viện `IconTile` 3 cột chia theo nhóm. Nhiều âm có thể phát cùng lúc. Thanh "Đang phát" ở đáy liệt kê bản phối, có nút Mix mở sheet `Slider` để chỉnh âm lượng từng âm, và hẹn giờ tắt (15, 30, 45, 60 phút, Custom). Trộn quá một âm là tính năng Premium. Màn hình hẹn giờ ngủ chuyển sang theme Bedtime và ẩn `TabBar`.
- **Timer**: `SegmentedControl` chuyển Fasting/Interval. `TimerRing` ở giữa. Một nút `primary` ở cuối ("Start fasting", "Start workout").
- **Cài bài tập ngắt quãng**: dòng tổng ở đầu (tổng thời gian và số khoảng), `FilterChips` cho các bài đã lưu (Tabata, HIIT 30/30, Custom), rồi các hàng `Stepper`: Prepare, Work, Rest, Rounds, Sets, Rest between sets. Nút `primary` "Start workout" luôn nằm ở đáy.
- **Streaks**: một `StreakCard` lớn cho chuỗi chính, các chuỗi khác dùng `size="sm"`, nút "Add habit" là `secondary`.
- **Money**: đầu tab là tháng hiện tại và số "Left to spend" bằng `money-xl`, dưới đó là hai nút lớn Expense và Income (học từ Monefy: thêm một khoản chỉ mất hai chạm). Tiếp theo là các `BudgetRow` theo phương pháp người dùng chọn (Envelopes hoặc 50/30/20), rồi các `TransactionRow` gần nhất. Chip "Offline · no bank link" luôn hiện ở đầu tab: đây là điểm bán hàng về quyền riêng tư.
- **Thêm khoản thu/chi**: `SegmentedControl` Expense/Income, số tiền `money-xl`, lưới `IconTile` danh mục, tài khoản và ngày, ghi chú, rồi `Keypad`. Nút "Save" là nút `primary` duy nhất.
- **Báo cáo**: chi tiêu theo danh mục là biểu đồ thanh ngang một màu `amber` (thanh dày tối đa 24px, đầu bo 4px, nhãn số ở cuối thanh bằng chữ `ink`), không dùng biểu đồ tròn. Danh sách giao dịch là bản dạng bảng của biểu đồ.
- **Check-in**: lời chào bằng `display`, `MoodPicker`, ô ghi chú tối đa 140 ký tự, nút "Save check-in".
- **Giới thiệu lần đầu (onboarding)**: ba màn, mỗi màn một nút `primary` và một lối "Skip". (1) "What brings you here?" với các `OptionCard` chọn nhiều, dùng để sắp xếp thứ tự tab và gợi ý âm. (2) Xin quyền thông báo: giải thích trước, đưa ví dụ lời nhắc thật, rồi mới gọi hộp thoại hệ thống. (3) Lời mời dùng thử với dòng thời gian minh bạch.
- **Premium**: âm thanh hoặc tính năng bị khoá vẫn hiện, có icon `lock`. Bấm vào thì mở sheet với hai lựa chọn: "Watch an ad to unlock for 24 hours" (quảng cáo có thưởng) hoặc "Try 3 days free" (paywall). Paywall có hai `PlanOption` (Monthly, Weekly), nêu rõ thời gian dùng thử và kỳ thanh toán, kèm dòng thời gian dùng thử: Today (mở khoá hết), Day 2 (nhắc trước khi tính tiền), Day 3 (bắt đầu tính tiền). Không dùng App Open Ads.
- **Không làm**: banner quảng cáo dính ở đáy nội dung; trang Settings toàn chữ dài; ép mua bằng khẩn cấp giả ("Only right now", "one-time offer"); số liệu đánh giá hay thống kê không có nguồn.
