import 'package:flutter/material.dart';

/// Central color palette for the Student OS design system.
///
/// FOREST / EMERALD / SAGE ONLY. Tonal layering runs dark -> medium -> muted
/// -> light -> almost-white:
///   Deep Forest -> Forest -> Muted Green -> Sage -> Soft Sage -> Pale Sage
///   -> Mist -> Natural White
///
/// There are no blue / purple / orange / yellow / red / cyan / pink UI accents.
/// Former accent names (`studentBlue`, `secondary`, `warning`, `streak`,
/// `error`, `info`, `neon*`) are retained ONLY as compatibility aliases and
/// all resolve into the green family. State is communicated through
/// iconography + text + shape + weight + opacity, not hue.
///
/// SOLID surfaces only — no glassmorphism, no blur, no neon.
///
/// UI code should almost never reference these raw values directly; prefer the
/// semantic colors exposed via `AppTheme.colorsOf(context)` or `ColorScheme`.
abstract final class AppColors {
  // === Green family — THE primary visual language ===
  static const Color deepForest = Color(0xFF123D35);
  static const Color forest = Color(0xFF285C4D);
  static const Color mutedGreen = Color(0xFF4F7D68);
  static const Color sage = Color(0xFF6F967F);
  static const Color softSage = Color(0xFFA9C1AE);
  static const Color paleSage = Color(0xFFE7EFDC);
  static const Color mist = Color(0xFFF2F6EC);
  static const Color naturalWhite = Color(0xFFFAFCF7);

  // Dark-mode green variants — deep emerald surfaces, not inverted light colors.
  static const Color veryDeepEmerald = Color(0xFF08211C);
  static const Color deepForestDark = Color(0xFF0C2924);
  static const Color forestDark = Color(0xFF1E3A32);
  static const Color mutedGreenDark = Color(0xFF3E6A57);
  static const Color sageDark = Color(0xFF8FB49A);
  static const Color softSageDark = Color(0xFF5E7D68);
  static const Color paleSageDark = Color(0xFF22382F);

  // === Primary (drives ColorScheme.primary) — Forest, the product identity ===
  static const Color primary = forest;
  static const Color primaryDark = deepForest;
  static const Color primaryContainer = paleSage;
  static const Color onPrimaryContainer = deepForest;

  // === Primary action accent — deep forest emerald (NOT blue) ===
  // Names retained for call-site compatibility; all resolve to green family.
  static const Color studentBlue = forest;
  static const Color studentBlueDark = deepForest;
  static const Color studentBlueContainer = paleSage;
  static const Color onStudentBlueContainer = deepForest;

  // Retained aliases for existing call sites (now green-family values).
  static const Color blue = studentBlue;
  static const Color blueDark = studentBlueDark;
  static const Color primaryBlue = studentBlue;
  static const Color primaryBlueDark = studentBlueDark;

  // === Secondary identity — sage tonal step (NOT purple) ===
  static const Color secondary = mutedGreen;
  static const Color secondaryContainer = paleSage;

  // === Semantic status — restrained green-family equivalents ===
  // success: emerald · warning: muted olive/sage · error: deep muted forest
  // (icon + label carry meaning) · info: deep sage · streak: deep emerald.
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFF7A8450);
  static const Color error = Color(0xFF2F453D);
  static const Color info = mutedGreen;
  static const Color streak = Color(0xFF1F5C44);

  // === Legacy neon aliases (all mapped into the green family) ===
  static const Color neonPink = error;
  static const Color neonBlue = forest;
  static const Color neonGreen = success;
  static const Color neonYellow = warning;
  static const Color neonOrange = warning;
  static const Color neonPurple = sage;

  // === Light Foundation (pale sage -> natural white tonal layering) ===
  static const Color backgroundLight = mist;
  static const Color backgroundSecondaryLight = paleSage;
  static const Color surfaceLight = naturalWhite;
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF4F7EF);

  // === Dark Foundation (deep emerald/forest, not inverted light) ===
  static const Color backgroundDark = veryDeepEmerald;
  static const Color backgroundSecondaryDark = deepForestDark;
  static const Color surfaceDark = deepForestDark;
  static const Color surfaceElevatedDark = forestDark;
  static const Color surfaceVariantDark = Color(0xFF1A322A);

  // === Text (light: deep forest ink · dark: soft sage ink) ===
  static const Color onSurfaceLight = Color(0xFF16241F);
  static const Color onSurfaceMutedLight = Color(0xFF5C6B63);
  static const Color onSurfaceDark = Color(0xFFEFF4EC);
  static const Color onSurfaceMutedDark = Color(0xFFA9BFAF);

  static const Color textPrimaryLight = Color(0xFF16241F);
  static const Color textSecondaryLight = Color(0xFF5C6B63);
  static const Color textTertiaryLight = Color(0xFF8B9A91);
  static const Color textDisabledLight = Color(0xFFC7D2C8);

  static const Color textPrimaryDark = Color(0xFFEFF4EC);
  static const Color textSecondaryDark = Color(0xFFA9BFAF);
  static const Color textTertiaryDark = Color(0xFF7A9484);
  static const Color textDisabledDark = Color(0xFF47625A);

  // === Legacy glass fields (retained for compat; NOT part of the DS) ===
  static const Color glassLight = naturalWhite;
  static const Color glassStrongLight = Color(0xFFFFFFFF);
  static const Color glassSubtleLight = paleSage;
  static const Color glassBorderLight = Color(0xFFD8E2D4);
  static const Color glassBorderStrongLight = Color(0xFFC6D4C3);

  static const Color glassDark = deepForestDark;
  static const Color glassStrongDark = forestDark;
  static const Color glassSubtleDark = Color(0xFF1A322A);
  static const Color glassBorderDark = Color(0xFF2B4A3E);
  static const Color glassBorderStrongDark = Color(0xFF37604F);

  static const Color outlineLight = Color(0xFFD8E2D4);
  static const Color outlineDark = Color(0xFF2B4A3E);

  // === Gradients (occasional hero areas only) ===
  static const Color rewardStart = forest;
  static const Color rewardEnd = sage;
  static const Color accentStart = forest;
  static const Color accentEnd = sage;
}
