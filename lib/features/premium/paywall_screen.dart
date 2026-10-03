import 'package:flutter/material.dart';

import '../../core/format/formatting.dart';
import '../../core/format/money_format.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/components/plan_option.dart';
import '../../ui/components/steady_button.dart';
import '../../ui/components/steady_icon.dart';
import '../../ui/components/steady_icon_button.dart';
import '../../ui/components/steady_inline_status.dart';
import 'premium_plans.dart';

String _planTitle(AppLocalizations l10n, PlanPeriod period) => switch (period) {
  PlanPeriod.monthly => l10n.planMonthly,
  PlanPeriod.weekly => l10n.planWeekly,
};

String _planPeriodLabel(AppLocalizations l10n, PlanPeriod period) =>
    switch (period) {
      PlanPeriod.monthly => l10n.planPerMonth,
      PlanPeriod.weekly => l10n.planPerWeek,
    };

String _planTerms(AppLocalizations l10n, PlanPeriod period, String price) =>
    switch (period) {
      PlanPeriod.monthly => l10n.paywallTermsMonthly(price),
      PlanPeriod.weekly => l10n.paywallTermsWeekly(price),
    };

/// Màn xem thử các gói Premium. Chưa thu tiền: nút chính chỉ hiện dòng báo
/// chưa mua được.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PlanPeriod _selected = kPremiumPlans.first.period;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    final l10n = AppLocalizations.of(context);
    final money = MoneyFormat(formatLocaleOf(context), kPlanCurrency);
    final benefits = [
      l10n.paywallBenefitSounds,
      l10n.paywallBenefitStreaks,
      l10n.paywallBenefitPlans,
      l10n.paywallBenefitHistory,
    ];
    final selectedPlan = kPremiumPlans.firstWhere((p) => p.period == _selected);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SteadySpace.s5,
                  SteadySpace.s3,
                  SteadySpace.s5,
                  SteadySpace.s6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: SteadyIconButton(
                        variant: SteadyIconButtonVariant.plain,
                        icon: SteadyIcons.x,
                        semanticLabel: l10n.close,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(height: SteadySpace.s5),
                    Text(
                      l10n.paywallOverline,
                      style: SteadyText.overline.copyWith(color: c.amber),
                    ),
                    const SizedBox(height: SteadySpace.s2),
                    Text(
                      l10n.paywallTitle,
                      style: SteadyText.display.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: SteadySpace.s5),
                    for (var i = 0; i < benefits.length; i++) ...[
                      if (i > 0) const SizedBox(height: SteadySpace.s3),
                      Row(
                        children: [
                          SteadyIcon(
                            SteadyIcons.check,
                            size: 20,
                            color: c.tide,
                          ),
                          const SizedBox(width: SteadySpace.s3),
                          Expanded(
                            child: Text(
                              benefits[i],
                              style: SteadyText.body.copyWith(color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: SteadySpace.s5),
                    Semantics(
                      container: true,
                      label: l10n.choosePlanLabel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final plan in kPremiumPlans) ...[
                            if (plan != kPremiumPlans.first)
                              const SizedBox(height: SteadySpace.s3),
                            PlanOption(
                              title: _planTitle(l10n, plan.period),
                              price: money.format(plan.priceMinor),
                              period: _planPeriodLabel(l10n, plan.period),
                              note: l10n.planTrialNote,
                              selected: plan.period == _selected,
                              onTap: () =>
                                  setState(() => _selected = plan.period),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: SteadySpace.s5),
                    if (_pressed) ...[
                      SteadyInlineStatus(message: l10n.paywallUnavailable),
                      const SizedBox(height: SteadySpace.s3),
                    ],
                    SteadyButton(
                      label: l10n.paywallCta,
                      onPressed: () => setState(() => _pressed = true),
                      variant: SteadyButtonVariant.primary,
                      block: true,
                    ),
                    const SizedBox(height: SteadySpace.s5),
                    Text(
                      _planTerms(
                        l10n,
                        selectedPlan.period,
                        money.format(selectedPlan.priceMinor),
                      ),
                      textAlign: TextAlign.center,
                      style: SteadyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
