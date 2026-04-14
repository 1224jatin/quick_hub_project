import 'package:flutter/material.dart';

import '../../core/theme.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  const AnimatedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bg = backgroundColor ?? (isDark ? AppTheme.white : AppTheme.primaryDarkBlue);
    final selected = selectedColor ?? (isDark ? AppTheme.primaryDarkBlue : AppTheme.white); // Neon Green from image
    final unselected = unselectedColor ?? (isDark ? Colors.white54 : Colors.grey);

    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 45),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          bool isSelected = currentIndex == index;
          return GestureDetector(
            onTap: () => onTap(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.only(bottom: 10,left: 10,right: 10,top:10),
              decoration: BoxDecoration(
                color: isSelected ? selected : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                items[index].icon,
                color: isSelected ? Colors.black : unselected,
                size: 35,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}
