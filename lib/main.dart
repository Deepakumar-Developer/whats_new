import 'package:flutter/material.dart';
import 'package:news_app/functions.dart';
import 'package:news_app/screens/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    customStatusBar(
        Color(0xff98EECC), Color(0xffF7F9F2), Brightness.dark, Brightness.dark);
    return MaterialApp(
      title: 'What\'s New',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xff98EECC),
          primary: Color(0xff91DDCF),
          secondary: Color(0xff98EECC),
          surface: Color(0xffF7F9F2),
          tertiary: Color(0xff0f0f0f),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'What\'s New'),
    );
  }
}
