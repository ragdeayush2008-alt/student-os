import 'package:flutter/material.dart';

/// Centralized raw and semantic color tokens for Student OS
/// Academic Command Center Design System (2.0 — solid surfaces).
///
/// UI code should read semantic colors via [AppTheme.colorsOf(context)] or [AppPalette].
abstract final class LiquidColors {
  // === Brand — forest/emerald/sage only (legacy names retained) ===
  static const Color primary = Color(0xFF285C4D); // Deep forest emerald
  static const Color primaryDark = Color(0xFF123D35);
  static const Color secondary = Color(0xFF4F7D68);
  static const Color accent = primary;
  static const Color accentSecondary = secondary;

  // === Accent Containers ===
  static const Color primaryContainerLight = Color(0xFFE7EFDC);
  static const Color primaryContainerDark = Color(0xFF22382F);
  static const Color secondaryContainerLight = Color(0xFFE7EFDC);
  static const Color secondaryContainerDark = Color(0xFF22382F);

  // === Semantic Status — green-family equivalents ===
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFF7A8450);
  static const Color error = Color(0xFF2F453D);
  static const Color info = Color(0xFF4F7D68);
  static const Color streak = Color(0xFF1F5C44); //

  // === Restrained accents (mapped to new identity) ===
  static const Color neonBlue = Color(0xFF285C4D);
  static const Color neonPurple = Color(0xFF6F967F);
  static const Color neonPink = Color(0xFF2F453D);
  static const Color neonGreen = Color(0xFF2E7D5B);
  static const Color neonYellow = Color(0xFF7A8450);
  static const Color neonOrange = Color(0xFF7A8450);

  // === Light Foundation (bright & clean) ===
  static const Color bgLight = Color(0xFFF6F8FC);
  static const Color bgSecondaryLight = Color(0xFFF1F4F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F4F9);

  // Legacy glass fields retained as SOLID values (no translucency in 2.0).
  static const Color glassLight = Color(0xFFFFFFFF);
  static const Color glassStrongLight = Color(0xFFFFFFFF);
  static const Color glassSubtleLight = Color(0xFFF1F4F9);
  static const Color glassBorderLight = Color(0xFFE4E7EC);
  static const Color glassBorderStrongLight = Color(0xFFE4E7EC);
  static const Color borderLight = Color(0xFFE4E7EC);
  static const Color borderStrongLight = Color(0xFFE4E7EC);

  static const Color textPrimaryLight = Color(0xFF101828);
  static const Color textSecondaryLight = Color(0xFF667085);
  static const Color textTertiaryLight = Color(0xFF98A2B3);
  static const Color textDisabledLight = Color(0xFFE4E7EC);

  // === Dark Foundation ===
  static const Color bgDark = Color(0xFF0D1117);
  static const Color bgSecondaryDark = Color(0xFF1D2430);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color surfaceElevatedDark = Color(0xFF1D2430);
  static const Color surfaceVariantDark = Color(0xFF1D2430);

  static const Color glassDark = Color(0xFF161B22);
  static const Color glassStrongDark = Color(0xFF1D2430);
  static const Color glassSubtleDark = Color(0xFF1D2430);
  static const Color glassBorderDark = Color(0xFF2A3342);
  static const Color glassBorderStrongDark = Color(0xFF2A3342);
  static const Color borderDark = Color(0xFF2A3342);
  static const Color borderStrongDark = Color(0xFF2A3342);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFA7B0C0);
  static const Color textTertiaryDark = Color(0xFF667085);
  static const Color textDisabledDark = Color(0xFF475569);

  // === Gradients (occasional hero areas only) ===
  static const List<Color> lightSpecularGradient = [
    Color(0x00FFFFFF),
    Color(0x00FFFFFF),
  ];

  static const List<Color> darkSpecularGradient = [
    Color(0x00FFFFFF),
    Color(0x00FFFFFF),
  ];

  static const List<Color> primaryGradient = [
    Color(0xFF123D35),
    Color(0xFF285C4D),
  ];

  static const List<Color> rewardGradient = [
    Color(0xFF285C4D),
    Color(0xFF6F967F),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF123D35),
    Color(0xFF285C4D),
  ];
}
