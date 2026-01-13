import 'dart:math';
import 'package:flutter/material.dart';

class PastelColors {
  static final List<Color> _colors = [
    // Original colors
    const Color(0xFFFFF1C1), // Light Yellow
    const Color(0xFFFFD6E0), // Light Pink
    const Color(0xFFC6E5FF), // Light Blue
    const Color(0xFFD6F4D2), // Light Green
    const Color(0xFFE7D3FF), // Light Purple
    const Color(0xFFFFE8C7), // Light Orange/Peach
    const Color(0xFFE4F3FF), // Pale Blue
    // New pastel colors
    const Color(0xFFFFE4EC), // Rose Pink
    const Color(0xFFD4F0F0), // Mint/Teal
    const Color(0xFFFCE4EC), // Blush Pink
    const Color(0xFFE8F5E9), // Mint Green
    const Color(0xFFFFF8E1), // Cream Yellow
    const Color(0xFFE1F5FE), // Sky Blue
    const Color(0xFFF3E5F5), // Lavender
  ];

  static final Random _rnd = Random();

  static Color getRandom() {
    return _colors[_rnd.nextInt(_colors.length)];
  }
}
