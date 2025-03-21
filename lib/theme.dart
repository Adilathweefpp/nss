import 'package:flutter/material.dart';

// NSS Colors
const Color primaryColor = Color(0xFF0066CC); // Blue
const Color secondaryColor = Color(0xFFFF9933); // Orange (From Indian flag)
const Color accentColor = Color(0xFF138808); // Green (From Indian flag)
const Color errorColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFFF5F5F5);

// App Theme
final ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    error: errorColor,
  ),
  scaffoldBackgroundColor: backgroundColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);