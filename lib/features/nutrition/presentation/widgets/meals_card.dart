import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/theme/design_tokens.dart';
import '../../data/kaloricke_tabulky_service.dart';

class MealsCard extends StatelessWidget {
  const MealsCard({
    super.key,
    required this.meals,
    required this.expanded,
    required this.onToggleMeal,
    required this.emojiFor,
  });

  final List<KtMeal> meals;
  final Set<String> expanded;
  final ValueChanged<String> onToggleMeal;
  final String Function(String id, String title) emojiFor;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final domain = Tokens.calories;
    final loggedMeals = meals.where((m) => m.hasFood).toList(); // lint-ignore: widget-no-logic — empty-meal display filter

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        decoration: domain.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: domain.dim,
                    borderRadius: BorderRadius.circular(Tokens.radiusIcon),
                    border: Border.all(
                      color: domain.color.withValues(alpha: 0.27),
                    ),
                  ),
                  child: Icon(Icons.restaurant_rounded,
                      size: 18, color: domain.color),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.nutritionMealsTitle,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeBody,
                    fontWeight: FontWeight.w700,
                    color: ft.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.spaceMd),
            if (loggedMeals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  l10n.nutritionMealsEmpty,
                  style: TextStyle(fontSize: 13, color: ft.onSurfaceMuted),
                ),
              )
            else
              for (int i = 0; i < loggedMeals.length; i++)
                _MealRow(
                  meal: loggedMeals[i],
                  emoji: emojiFor(loggedMeals[i].id, loggedMeals[i].title),
                  expanded: expanded.contains(loggedMeals[i].id),
                  onTap: () => onToggleMeal(loggedMeals[i].id),
                  isLast: i == loggedMeals.length - 1,
                ),
          ],
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.emoji,
    required this.expanded,
    required this.onTap,
    required this.isLast,
  });

  final KtMeal meal;
  final String emoji;
  final bool expanded;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    final l10n = context.l10n;
    final color = Tokens.calories.color;

    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: ft.divider)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: Tokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meal.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ft.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.nutritionFoodItems(meal.foodstuff.length),
                          style: TextStyle(
                            fontSize: Tokens.fontSizeMicro,
                            color: ft.onSurfaceMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: meal.energyTotal.round().toString(),
                      style: TextStyle(
                        fontSize: Tokens.fontSizeBody,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                      children: [
                        TextSpan(
                          text: ' kcal',
                          style: TextStyle(
                            fontSize: Tokens.fontSizeMicro,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ft.onSurfaceMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              heightFactor: expanded ? 1.0 : 0.0,
              child: RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, Tokens.spaceSm),
                  child: Column(
                    children: [
                      for (final f in meal.foodstuff) _FoodstuffRow(food: f),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodstuffRow extends StatelessWidget {
  const _FoodstuffRow({required this.food});

  final KtFoodstuff food;

  @override
  Widget build(BuildContext context) {
    final ft = context.ft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  food.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ft.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${food.energy.round()} kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Tokens.calories.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            children: [
              if (food.unit.isNotEmpty)
                Text(
                  food.unit,
                  style: TextStyle(
                    fontSize: Tokens.fontSizeMicro,
                    color: ft.onSurfaceMuted,
                  ),
                ),
              const Spacer(),
              _FoodMacroDot(
                value: food.protein,
                color: Tokens.protein.color,
                label: 'P',
              ),
              const SizedBox(width: 8),
              _FoodMacroDot(
                value: food.fat,
                color: Tokens.fat.color,
                label: 'F',
              ),
              const SizedBox(width: 8),
              _FoodMacroDot(
                value: food.carbs,
                color: Tokens.carbs.color,
                label: 'C',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoodMacroDot extends StatelessWidget {
  const _FoodMacroDot({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        children: [
          TextSpan(
            text: '${value.toStringAsFixed(1)}g',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
