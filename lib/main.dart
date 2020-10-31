import 'package:abbys/screen/home.dart';
import 'package:abbys/screen/password.dart';
import 'package:abbys/screen/start.dart';
import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:abbys/service/route.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final DbService _service = new DbService();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Map<int, Color> color = {
      50: Color.fromRGBO(4, 131, 184, .1),
      100: Color.fromRGBO(4, 131, 184, .2),
      200: Color.fromRGBO(4, 131, 184, .3),
      300: Color.fromRGBO(4, 131, 184, .4),
      400: Color.fromRGBO(4, 131, 184, .5),
      500: Color.fromRGBO(4, 131, 184, .6),
      600: Color.fromRGBO(4, 131, 184, .7),
      700: Color.fromRGBO(4, 131, 184, .8),
      800: Color.fromRGBO(4, 131, 184, .9),
      900: Color.fromRGBO(4, 131, 184, 1),
    };
    return MaterialApp(
      title: 'Abyss Library',
      theme: ThemeData(
        primarySwatch: MaterialColor(THEME_COLOR, color),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: PasswordScreen(_service),
      routes: {
        Routes.startScreen: (context) {
          return StartScreen(_service);
        },
        Routes.homeScreen: (context) {
          return HomeScreen(_service);
        },
        Routes.passwordScreen: (context) {
          return PasswordScreen(_service);
        }
      },
    );
  }
}
