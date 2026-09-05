import 'package:flutter/material.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/theme/app_colors.dart';

class ModeChips extends StatelessWidget {
  const ModeChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CultureMode selected;
  final ValueChanged<CultureMode> onSelected;

  @override
  Widget build(BuildContext context) {
    const visibleModes = [
      CultureMode.watch,
      CultureMode.play,
      CultureMode.read,
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleModes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mode = visibleModes[index];
          final isSelected = mode == selected;
          final info = modeCatalog[mode]!;
          final accent = switch (mode) {
            CultureMode.watch => AppColors.watch,
            CultureMode.play => AppColors.play,
            CultureMode.read => AppColors.read,
          };

          return Semantics(
            button: true,
            selected: isSelected,
            label: info.label,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () => onSelected(mode),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isSelected
                        ? AppColors.brandAction
                        : AppColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandAction
                          : AppColors.line,
                    ),
                    boxShadow: const [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        info.icon,
                        size: 18,
                        color: isSelected ? Colors.black : accent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        info.label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : AppColors.ink,
                          fontSize: 14.5,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
