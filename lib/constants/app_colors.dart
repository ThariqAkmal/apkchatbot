import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color primaryBackground = Color(
    0xFF0F172A,
  ); // biru gelap sangat pekat
  static const Color secondaryBackground = Color(
    0xFF1E293B,
  ); // biru gelap (header & input area)

  // Chat Bubble Colors
  static const Color userBubble = Color(0xFF3B82F6); // biru untuk user
  static const Color botBubble = Color(0xFF334155); // abu-abu gelap untuk bot

  // Text Colors
  static const Color primaryText = Color(0xFFF8FAFC); // putih keabu-abuan
  static const Color secondaryTextLight = Color(0xFF9CA3AF); // abu-abu terang
  static const Color secondaryTextDark = Color(
    0xFF6B7280,
  ); // abu-abu terang gelap

  // Additional Colors
  static const Color accent = Color(0xFF3B82F6); // untuk tombol dan aksen
  static const Color error = Color(0xFFEF4444); // merah untuk error
  static const Color success = Color(0xFF10B981); // hijau untuk success
  static const Color warning = Color(0xFFF59E0B); // kuning untuk warning

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
