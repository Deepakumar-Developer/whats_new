import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

double width(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double height(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

void customStatusBar(var statusBarColor, systemNavigationBarColor,
    statusBarIconBrightness, systemNavigationBarIconBrightness) {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: statusBarColor,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: statusBarIconBrightness,
    systemNavigationBarColor: systemNavigationBarColor,
    systemNavigationBarIconBrightness: systemNavigationBarIconBrightness,
  ));
}

List<Map<String, dynamic>> article = [];

void showToast(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xff0f0f0f),
      textColor: Colors.white,
      fontSize: 16.0);
}

List<Map<String, String>> countryNames = [
  {'countryCode': 'in', 'countryName': 'India'},
  {'countryCode': 'us', 'countryName': 'United States'},
  {'countryCode': 'at', 'countryName': 'Austria'},
  {'countryCode': 'au', 'countryName': 'Australia'},
  {'countryCode': 'ca', 'countryName': 'Canada'},
  {'countryCode': 'cn', 'countryName': 'China'},
  {'countryCode': 'gb', 'countryName': 'United Kingdom'},
  {'countryCode': 'jp', 'countryName': 'Japan'},
  {'countryCode': 'mx', 'countryName': 'Mexico'},
  {'countryCode': 'my', 'countryName': 'Malaysia'},
  {'countryCode': 'nz', 'countryName': 'New Zealand'},
  {'countryCode': 'ru', 'countryName': 'Russia'},
  {'countryCode': 'ph', 'countryName': 'Philippines'},
  {'countryCode': 'sg', 'countryName': 'Singapore'},
  {'countryCode': 'za', 'countryName': 'South Africa'},
  {'countryCode': 'th', 'countryName': 'Thailand'},
  {'countryCode': 'ua', 'countryName': 'Ukraine'},
];
