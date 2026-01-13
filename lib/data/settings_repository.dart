import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsRepository {
  static const String _boxName = 'settingsBox';
  static Box? _box;

  // Keys
  static const String _kThemeMode = 'themeMode'; // 'light'|'dark'|'system'
  static const String _kFontSize = 'fontSize'; // double
  static const String _kNoteLayout = 'noteLayout'; // 'list' or 'grid'
  static const String _kSortOrder = 'sortOrder'; // 'updated' or 'created' or 'title'

  // Must be called once at startup (before reading settings)
  static Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox(_boxName);
  }

  // ---------- Theme Mode ----------
  static ThemeMode getThemeMode() {
    final v = _box?.get(_kThemeMode) as String?;
    if (v == null || v == 'system') return ThemeMode.system;
    return v == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await init();
    final s = mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system');
    await _box!.put(_kThemeMode, s);
  }

  // ---------- Font Size ----------
  static double getFontSize() {
    final v = _box?.get(_kFontSize);
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return 16.0; // default font size
  }

  static Future<void> setFontSize(double size) async {
    await init();
    await _box!.put(_kFontSize, size);
  }

  // ---------- Note Layout ----------
  static String getNoteLayout() {
    final v = _box?.get(_kNoteLayout) as String?;
    return v ?? 'list';
  }

  static Future<void> setNoteLayout(String layout) async {
    await init();
    await _box!.put(_kNoteLayout, layout);
  }

  // ---------- Sort Order ----------
  static String getSortOrder() {
    final v = _box?.get(_kSortOrder) as String?;
    return v ?? 'updated';
  }

  static Future<void> setSortOrder(String order) async {
    await init();
    await _box!.put(_kSortOrder, order);
  }
}