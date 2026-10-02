import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import 'steady_icon.dart';

class SteadyTabItem {
  const SteadyTabItem(this.icon, this.label);

  final String icon;
  final String label;
}

class SteadyTabBar extends StatelessWidget {
  const SteadyTabBar({
    super.key,
    required this.items,
    required this.current,
    required this.onChanged,
  });

  final List<SteadyTabItem> items;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              height: SteadySize.tabbar,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _Tab(
                        item: items[i],
                        selected: i == current,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final SteadyTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SteadyColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.amberSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(SteadyRadius.full),
              ),
              child: SteadyIcon(
                item.icon,
                size: 22,
                color: selected ? c.amber : c.inkMuted,
              ),
            ),
            const SizedBox(height: SteadySpace.s1),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SteadyText.caption.copyWith(
                color: selected ? c.ink : c.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
