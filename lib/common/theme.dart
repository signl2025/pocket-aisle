import 'package:flutter/material.dart';

//stores light theme data, default
final lightTheme = ThemeData(
  colorSchemeSeed: Colors.indigoAccent,
  brightness: Brightness.light,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Corben',
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Colors.black,
    ),
  ),
);

//stores dark theme data
final darkTheme = ThemeData(
  colorSchemeSeed: Colors.indigoAccent,
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Corben',
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: Colors.white,
    ),
  ),
);
