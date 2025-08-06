import 'package:flutter/material.dart';

class AppColors {
  // Background Colors - Modern White Theme
  static const Color primaryBackground = Color(
    0xFFFFFFFF,
  ); // Pure white background
  static const Color secondaryBackground = Color(
    0xFFFAFAFA,
  ); // Light gray for cards/containers
  static const Color cardBackground = Color(
    0xFFF8F9FA,
  ); // Subtle gray for elevated elements

  // Chat Bubble Colors
  static const Color userBubble = Color(
    0xFFF3F4F6,
  ); // Light gray for user messages
  static const Color botBubble = Color(
    0xFFFFFFFF,
  ); // White for bot messages with border

  // Text Colors - Optimized for white background
  static const Color primaryText = Color(0xFF111827); // Dark gray for main text
  static const Color secondaryText = Color(
    0xFF6B7280,
  ); // Medium gray for secondary text
  static const Color lightText = Color(
    0xFF9CA3AF,
  ); // Light gray for subtle text
  static const Color whiteText = Color(
    0xFFFFFFFF,
  ); // White text for dark backgrounds

  // Gradient Colors - Pinterest Red Theme
  static const Color gradientStart = Color(0xFFE60023); // Pinterest Red
  static const Color gradientMiddle = Color(0xFFFF1744); // Bright Red
  static const Color gradientEnd = Color(0xFFFF5722); // Red Orange

  // Additional Colors
  static const Color accent = Color(
    0xFFE60023,
  ); // Pinterest Red for primary actions
  static const Color error = Color(0xFFE60023); // Pinterest Red for errors
  static const Color success = Color(0xFF059669); // Green for success
  static const Color warning = Color(0xFFF59E0B); // Yellow for warnings
  static const Color info = Color(0xFF0EA5E9); // Blue for information

  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB); // Light border
  static const Color borderMedium = Color(0xFFD1D5DB); // Medium border
  static const Color borderDark = Color(0xFF9CA3AF); // Dark border

  // Gradients - Main gradient palette
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientMiddle, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [
      Color(0xFFFCE4EC),
      Color(0xFFF8BBD9),
    ], // Subtle light pink to medium light pink
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [gradientStart, gradientMiddle],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [gradientMiddle, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x0A000000); // Very light shadow
  static const Color shadowMedium = Color(0x1A000000); // Medium shadow
  static const Color shadowDark = Color(0x33000000); // Darker shadow

  // Status Colors with gradient variations
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFE60023), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
