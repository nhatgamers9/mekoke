import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../core/time/local_date.dart';
import '../../data/database.dart';
import '../../data/money_types.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/steady_icon.dart';

String categoryLabel(AppLocalizations l10n, MoneyCategory c) => switch (c) {
  MoneyCategory.groceries => l10n.catGroceries,
  MoneyCategory.eatingOut => l10n.catEatingOut,
  MoneyCategory.transport => l10n.catTransport,
  MoneyCategory.bills => l10n.catBills,
  MoneyCategory.shopping => l10n.catShopping,
  MoneyCategory.health => l10n.catHealth,
  MoneyCategory.gifts => l10n.catGifts,
  MoneyCategory.housing => l10n.catHousing,
  MoneyCategory.travel => l10n.catTravel,
  MoneyCategory.phone => l10n.catPhone,
  MoneyCategory.education => l10n.catEducation,
  MoneyCategory.other => l10n.catOther,
};

String categoryIcon(MoneyCategory c) => switch (c) {
  MoneyCategory.groceries => SteadyIcons.shoppingCart,
  MoneyCategory.eatingOut => SteadyIcons.coffee,
  MoneyCategory.transport => SteadyIcons.car,
  MoneyCategory.bills => SteadyIcons.zap,
  MoneyCategory.shopping => SteadyIcons.shirt,
  MoneyCategory.health => SteadyIcons.heartPulse,
  MoneyCategory.gifts => SteadyIcons.gift,
  MoneyCategory.housing => SteadyIcons.house,
  MoneyCategory.travel => SteadyIcons.plane,
  MoneyCategory.phone => SteadyIcons.smartphone,
  MoneyCategory.education => SteadyIcons.graduationCap,
  MoneyCategory.other => SteadyIcons.receipt,
};

/// Số tiền của một khoản chi, kèm dấu "−".
String expenseAmount(AppLocalizations l10n, MoneyFormat m, int minor) =>
    l10n.amountExpense(m.format(minor));

/// Ghi chú nếu có, không thì tên danh mục.
String entryTitle(AppLocalizations l10n, MoneyEntry e) =>
    e.note ?? categoryLabel(l10n, e.category);

/// Dòng chi tiết dưới tiêu đề. Giờ chỉ hiện khi khoản được tạo đúng vào ngày
/// của nó (sửa lại một khoản cũ không đổi giờ tạo, nên giờ đó không còn ý
/// nghĩa với ngày mới). Không có gì để hiện thì trả `null`.
String? entryDetail(
  AppLocalizations l10n,
  MoneyEntry e, {
  required String tag,
  required bool use24h,
}) {
  final time = LocalDate.fromDateTime(e.createdAt) == e.date
      ? formatClockTime(e.createdAt, tag, use24h: use24h)
      : null;
  final note = e.note;
  if (note == null) return time;
  final category = categoryLabel(l10n, e.category);
  return time == null ? category : l10n.entryDetailLine(category, time);
}

/// Tiêu đề nhóm trong danh sách: TODAY, YESTERDAY, "OCT 1", "DEC 31, 2025".
String dayHeader(
  AppLocalizations l10n,
  LocalDate d,
  LocalDate today,
  String tag,
) {
  if (d == today) return l10n.dayToday;
  if (d == today.addDays(-1)) return l10n.dayYesterday;
  return formatShortDate(d, today, tag).toUpperCase();
}

/// Nhãn ngày trên nút chọn ngày: Today, Yesterday, "Oct 1".
String dateLabel(
  AppLocalizations l10n,
  LocalDate d,
  LocalDate today,
  String tag,
) {
  if (d == today) return l10n.dateToday;
  if (d == today.addDays(-1)) return l10n.dateYesterday;
  return formatShortDate(d, today, tag);
}
