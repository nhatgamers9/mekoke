// Dữ liệu hai gói Premium. Đây là giá tạm để hiển thị: khi nối cửa hàng thì
// thay bằng giá cửa hàng trả về. Giá chỉ ghi ở file này.

enum PlanPeriod { monthly, weekly }

class PremiumPlan {
  const PremiumPlan({required this.period, required this.priceMinor});

  final PlanPeriod period;

  /// Đơn vị nhỏ nhất của [kPlanCurrency]: 999 là 9.99.
  final int priceMinor;
}

/// Mã tiền tệ ISO 4217 của hai mức giá.
const String kPlanCurrency = 'USD';

/// Thứ tự hiển thị; phần tử đầu được chọn sẵn.
const List<PremiumPlan> kPremiumPlans = [
  PremiumPlan(period: PlanPeriod.monthly, priceMinor: 999),
  PremiumPlan(period: PlanPeriod.weekly, priceMinor: 499),
];
