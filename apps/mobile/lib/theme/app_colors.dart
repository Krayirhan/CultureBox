import 'package:flutter/material.dart';

class AppColors {
  /// CultureBox is deliberately dark so artwork—not chrome—carries discovery.
  static const background = Color(0xFF101112);
  static const surface = Color(0xFF17191C);
  static const card = Color(0xFF1C1E22);
  static const hero = Color(0xFF151719);
  static const ink = Color(0xFFF5F1EB);
  static const muted = Color(0xFF9C9790);
  static const line = Color(0xFF38393B);

  // One global action color; mode colors are reserved for compact category cues.
  static const brandAction = Color(0xFFC9654E);
  static const brandActionSoft = Color(0x33C9654E);
  static const onBrandAction = Color(0xFF101112);
  static const destructive = Color(0xFFFF8B82);
  // Compatibility aliases for older surfaces while they adopt semantic names.
  static const olive = brandAction;
  static const oliveSoft = brandActionSoft;
  static const watch = Color(0xFFC9654E);
  static const play = Color(0xFFC6F135);
  static const read = Color(0xFF5BC0EB);
  static const rating = Color(0xFFF6C453);

  // Community is intentionally separate from the discovery accents: it reads
  // as a calm, trusted personal space instead of another call-to-action.
  static const communitySurface = Color(0xFF20271F);
  static const communityLine = Color(0xFF495545);
  static const communityAccent = Color(0xFFADB992);
  static const communitySoft = Color(0x26495545);
}
