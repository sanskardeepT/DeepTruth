import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';

class CategoryTabBar extends StatefulWidget {
  final void Function(String category) onCategoryChanged;

  const CategoryTabBar({super.key, required this.onCategoryChanged});

  @override
  State<CategoryTabBar> createState() => _CategoryTabBarState();
}

class _CategoryTabBarState extends State<CategoryTabBar> {
  String _selected = 'all';

  static const _labels = {
    'all':        AppStrings.catAll,
    'politics':   AppStrings.catPolitics,
    'health':     AppStrings.catHealth,
    'technology': AppStrings.catTech,
    'business':   AppStrings.catBusiness,
    'sports':     AppStrings.catSports,
    'world':      AppStrings.catWorld,
    'science':    AppStrings.catScience,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: AppConstants.newsCategories.map((cat) {
          final isSelected = cat == _selected;
          return GestureDetector(
            onTap: () {
              if (cat == _selected) return;
              if (mounted) setState(() => _selected = cat);
              widget.onCategoryChanged(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:  const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.divider,
                ),
              ),
              child: Text(
                _labels[cat] ?? cat,
                style: TextStyle(
                  color:      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize:   12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
