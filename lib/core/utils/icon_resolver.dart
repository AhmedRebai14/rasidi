import 'package:flutter/material.dart';

/// Resolves a stored icon codepoint string back to a const [IconData].
/// All icons must come from [availableIcons] — this avoids non-const
/// [IconData] construction that breaks Flutter release tree-shaking.
class IconResolver {
  IconResolver._();

  /// The single source-of-truth icon list used across add/edit category
  /// and all display sites.
  static const List<IconData> availableIcons = [
    Icons.fastfood,
    Icons.directions_car,
    Icons.home,
    Icons.lightbulb,
    Icons.shopping_bag,
    Icons.medication,
    Icons.movie,
    Icons.category,
    Icons.work,
    Icons.laptop,
    Icons.card_giftcard,
    Icons.sports_esports,
    Icons.flight,
    Icons.fitness_center,
    Icons.pets,
    Icons.coffee,
    Icons.school,
    Icons.restaurant,
    Icons.local_hospital,
    Icons.music_note,
    Icons.book,
    Icons.beach_access,
    Icons.local_gas_station,
    Icons.wifi,
    Icons.smartphone,
    Icons.tv,
    Icons.attach_money,
    Icons.savings,
  ];

  /// Returns the [IconData] whose [codePoint] matches [iconStr].
  /// Falls back to [Icons.category] if not found.
  static IconData resolve(String? iconStr) {
    final code = int.tryParse(iconStr ?? '');
    if (code == null) return Icons.category;
    for (final icon in availableIcons) {
      if (icon.codePoint == code) return icon;
    }
    return Icons.category;
  }
}
