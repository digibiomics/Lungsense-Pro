import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class LsNavItem {
  const LsNavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Role bottom navigation (Dashboard/PatientHome/AdminDoctors): 72px white
/// bar, top border, active item on a primary 35% pill.
class LsBottomNav extends StatelessWidget {
  const LsBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<LsNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: LsSize.bottomNav,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(child: _item(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final active = i == currentIndex;
    final item = items[i];
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(i),
        containedInkWell: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              height: 28,
              decoration: BoxDecoration(
                color: active ? LsTint.navActive : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                size: 22,
                color: active ? AppColors.text : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LsText.pill.copyWith(
                color: active ? AppColors.text : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
