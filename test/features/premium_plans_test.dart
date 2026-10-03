import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:steady/core/format/money_format.dart';
import 'package:steady/features/premium/premium_plans.dart';

void main() {
  group('kPremiumPlans', () {
    test('has exactly two plans: monthly first, then weekly', () {
      expect(kPremiumPlans, hasLength(2));
      expect(kPremiumPlans.map((p) => p.period).toList(), [
        PlanPeriod.monthly,
        PlanPeriod.weekly,
      ]);
    });

    test('monthly costs 9.99 and weekly costs 4.99 (minor units)', () {
      expect(kPremiumPlans[0].priceMinor, 999);
      expect(kPremiumPlans[1].priceMinor, 499);
    });

    test('the plan currency is USD', () {
      expect(kPlanCurrency, 'USD');
    });

    test('the first plan (the preselected one) is monthly', () {
      expect(kPremiumPlans.first.period, PlanPeriod.monthly);
    });

    test('each period appears once, so exactly one plan can be selected', () {
      final periods = kPremiumPlans.map((p) => p.period).toSet();
      expect(periods, hasLength(kPremiumPlans.length));
      expect(periods, PlanPeriod.values.toSet());
    });

    test('every price is a positive whole number of minor units', () {
      for (final p in kPremiumPlans) {
        expect(p.priceMinor, isPositive);
      }
    });
  });

  group('plan prices through MoneyFormat', () {
    setUpAll(() async {
      await initializeDateFormatting();
    });

    test(r'an English phone sees $9.99 and $4.99', () {
      final money = MoneyFormat('en_US', kPlanCurrency);
      expect(money.format(kPremiumPlans[0].priceMinor), r'$9.99');
      expect(money.format(kPremiumPlans[1].priceMinor), r'$4.99');
    });

    test('a phone that falls back to the plain en tag sees the same', () {
      final money = MoneyFormat('en', kPlanCurrency);
      expect(money.format(kPremiumPlans[0].priceMinor), r'$9.99');
      expect(money.format(kPremiumPlans[1].priceMinor), r'$4.99');
    });
  });
}
