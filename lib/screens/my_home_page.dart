import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lecle_system_shortcuts/lecle_system_shortcuts.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';

import '../functions.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String check = 'check';
  StreamSubscription? listener;
  FlutterTts flutterTts = FlutterTts();
  final customCategory = TextEditingController();
  String searchArticle = '', speakWord = '', countryCode = 'in';
  int? startIndex;
  int? endIndex;
  bool connection = true;
  bool allSelected = true,
      showDragField = false,
      turnOn = false,
      speakerContainer = false;
  List<bool> searchElement = [false, false, false, false, false];

  static const String _apiKey = "2723ede1643242b4891b3335371061eb";
  static const String _baseUrl = "https://newsapi.org/v2/";

  Future<void> getArticle({String search = 'general'}) async {
    final url = Uri.parse("${_baseUrl}everything?q=$search&apiKey=$_apiKey");
    setState(() {
      article = [];
    });
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List;
      for (var json in articles) {
        setState(() {
          if ((json['content']?.toString() ?? '').isNotEmpty &&
              (json['content']?.toString() ?? '') != '[Removed]') {
            article.add({
              'author': json['author']?.toString() ?? 'Private Author',
              'publishedAt': json['publishedAt']?.toString() ?? 'Present',
              'title': json['title']?.toString() ?? '',
              'description': json['description']?.toString() ?? '',
              'content': json['content']?.toString() ?? '',
              'url': json['url']?.toString() ?? '',
              'urlToImage': json['urlToImage']?.toString() ?? '',
            });
          }
        });
      }
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<void> getTopHeadline(String country) async {
    final url =
        Uri.parse("${_baseUrl}top-headlines?country=$country&apiKey=$_apiKey");
    setState(() {
      article = [];
    });
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List;
      for (var json in articles) {
        setState(() {
          if ((json['content']?.toString() ?? '').isNotEmpty &&
              (json['content']?.toString() ?? '') != '[Removed]') {
            article.add({
              'author': json['author']?.toString() ?? 'Private Author',
              'publishedAt': json['publishedAt']?.toString() ?? 'Present',
              'title': json['title']?.toString() ?? '',
              'description': json['description']?.toString() ?? '',
              'content': json['content']?.toString() ?? '',
              'url': json['url']?.toString() ??
                  'https://bitwisesample.netlify.app',
              'urlToImage': json['urlToImage']?.toString() ?? '',
            });
          }
        });
      }
      if (article.isEmpty) {
        setState(() {
          article.add({
            'article': 'Not Article',
          });
        });
      }
    } else {
      throw Exception('Failed to load news');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initVoice();
    listener =
        InternetConnection().onStatusChange.listen((InternetStatus status) {
      switch (status) {
        case InternetStatus.connected:
          setState(() {
            connection = true;
            turnOn = false;
          });
          break;
        case InternetStatus.disconnected:
          setState(() {
            turnOn = false;
            connection = false;
          });
          break;
        default:
          setState(() {
            connection = false;
          });
          break;
      }
      if (searchArticle.isEmpty) {
        getTopHeadline(countryCode);
      } else {
        getArticle(search: searchArticle);
      }
    });
  }

  void initVoice() {
    flutterTts.getDefaultVoice.then((data) async {
      setState(() {
        flutterTts.setVoice({'name': data['name'], 'locale': data['locale']});
      });
    });
    flutterTts.setProgressHandler((text, start, end, word) {
      setState(() {
        startIndex = start;
        endIndex = end;
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    listener?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: width(context) < height(context)
            ? Container(
                width: width(context),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'What\'s New',
                                style: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary),
                                ),
                              ),
                              Container(
                                height: 45,
                                width: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(40),
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                child: DropdownButton<String>(
                                  value: countryCode,
                                  onChanged: (newValue) {
                                    setState(() {
                                      countryCode = newValue!;
                                      searchArticle = '';
                                      allSelected = true;
                                      for (var countryName in countryNames) {
                                        if (countryName['countryCode'] ==
                                            countryCode.toLowerCase()) {
                                          showToast(
                                              'News! from ${countryName['countryName']}');
                                          break;
                                        }
                                      }
                                      getTopHeadline(countryCode.toLowerCase());
                                    });
                                  },
                                  style: GoogleFonts.outfit(
                                      textStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  )),
                                  dropdownColor:
                                      Theme.of(context).colorScheme.secondary,
                                  borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(15)),
                                  menuMaxHeight: 250,
                                  items: countryNames
                                      .map((option) => DropdownMenuItem(
                                            value: option['countryCode'],
                                            child: Text(
                                              option['countryCode']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                  textStyle: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary,
                                              )),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (connection) {
                                        allSelected = true;
                                        showDragField = false;
                                        searchArticle = '';
                                        getTopHeadline(countryCode);
                                      } else {
                                        showToast('Check You Internet');
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 7.5),
                                    decoration: BoxDecoration(
                                        color: allSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5)),
                                        boxShadow: const [
                                           BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 0),
                                            blurRadius: 15,
                                          )
                                        ]),
                                    child: Text(
                                      'All',
                                      style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w300,
                                        color: !allSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                      )),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (connection) {
                                        showDragField = true;
                                        if (!allSelected) {
                                          allSelected = true;
                                          showDragField = false;
                                          getTopHeadline(countryCode);
                                          searchElement[0] = false;
                                          searchElement[1] = false;
                                          searchElement[2] = false;
                                          searchElement[3] = false;
                                          searchElement[4] = false;
                                          searchArticle = '';
                                        } else {
                                          allSelected = false;
                                        }
                                      } else {
                                        showToast('Check Your Internet');
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 7.5),
                                    decoration: BoxDecoration(
                                        color: !allSelected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .tertiary
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5)),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 0),
                                            blurRadius: 15,
                                          )
                                        ]),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Search',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w300,
                                            color: allSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                          )),
                                        ),
                                        const SizedBox(
                                          width: 2,
                                        ),
                                        if (!allSelected)
                                          Icon(
                                            size: 20,
                                            Icons.clear,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                                if (searchArticle.isNotEmpty)
                                  Icon(
                                    Icons.arrow_left_rounded,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    size: 30,
                                  ),
                                if (searchArticle.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 7.5),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(5)),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0, 0),
                                            blurRadius: 15,
                                          )
                                        ]),
                                    child: Text(
                                      searchArticle,
                                      style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w300,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      )),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: article.isNotEmpty
                                ? !(article.length == 1 &&
                                        article[0]['article'] == 'Not Article')
                                    ? SizedBox(
                                        width: width(context),
                                        child: ListView.builder(
                                            itemCount: article.length + 1,
                                            itemBuilder: (context, index) {
                                              if (index == article.length) {
                                                return SizedBox(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Powered by : ',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          textStyle: TextStyle(
                                                            fontSize: 10,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        'ByteWise Creators',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          textStyle: TextStyle(
                                                            fontSize: 10,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: article[index]
                                                                    ['author']
                                                                .toString()
                                                                .isNotEmpty ||
                                                            article[index][
                                                                    'publishedAt']
                                                                .toString()
                                                                .isNotEmpty
                                                        ? 60
                                                        : 20,
                                                    width: width(context),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            if (article[index]
                                                                    ['author']
                                                                .toString()
                                                                .isNotEmpty)
                                                              SizedBox(
                                                                width: width(
                                                                        context) *
                                                                    0.75,
                                                                height: 20,
                                                                child:
                                                                    TextScroll(
                                                                  article[index]
                                                                      [
                                                                      'author'],
                                                                  mode: TextScrollMode
                                                                      .endless,
                                                                  velocity: const Velocity(
                                                                      pixelsPerSecond:
                                                                          Offset(
                                                                              50,
                                                                              0)),
                                                                  delayBefore:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              50000),
                                                                  pauseBetween:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              2000),
                                                                  style: GoogleFonts.outfit(
                                                                      textStyle: TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .tertiary)),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .right,
                                                                  selectable:
                                                                      true,
                                                                ),
                                                              ),
                                                            if (article[index][
                                                                    'publishedAt']
                                                                .toString()
                                                                .isNotEmpty)
                                                              Row(
                                                                children: [
                                                                  Text(
                                                                    article[index]
                                                                            [
                                                                            'publishedAt']
                                                                        .toString()
                                                                        .substring(
                                                                            0,
                                                                            10),
                                                                    style: GoogleFonts.outfit(
                                                                        textStyle: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Theme.of(context).colorScheme.tertiary,
                                                                            fontWeight: FontWeight.w200)),
                                                                  ),
                                                                  Text(
                                                                    '  ||  ',
                                                                    style: GoogleFonts.outfit(
                                                                        textStyle: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Theme.of(context).colorScheme.tertiary,
                                                                            fontWeight: FontWeight.w200)),
                                                                  ),
                                                                  Text(
                                                                    article[index]
                                                                            [
                                                                            'publishedAt']
                                                                        .toString()
                                                                        .substring(
                                                                            11,
                                                                            19),
                                                                    style: GoogleFonts.outfit(
                                                                        textStyle: TextStyle(
                                                                            fontSize:
                                                                                10,
                                                                            color:
                                                                                Theme.of(context).colorScheme.tertiary,
                                                                            fontWeight: FontWeight.w200)),
                                                                  ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                        if (article[index]
                                                                ['description']
                                                            .toString()
                                                            .isNotEmpty)
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                speakerContainer =
                                                                    true;
                                                                speakWord = article[
                                                                        index][
                                                                    'description'];
                                                              });
                                                              flutterTts.speak(
                                                                  article[index]
                                                                      [
                                                                      'description']);
                                                            },
                                                            child: Icon(
                                                              Icons
                                                                  .volume_up_rounded,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                            ),
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  SizedBox(
                                                    width: width(context),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        if (article[index]
                                                                ['title']
                                                            .toString()
                                                            .isNotEmpty)
                                                          SizedBox(
                                                            height: 35,
                                                            child: TextScroll(
                                                              '${article[index]['title']}',
                                                              mode:
                                                                  TextScrollMode
                                                                      .endless,
                                                              velocity: const Velocity(
                                                                  pixelsPerSecond:
                                                                      Offset(50,
                                                                          0)),
                                                              delayBefore:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          1000),
                                                              pauseBetween:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          2000),
                                                              style: GoogleFonts.outfit(
                                                                  textStyle: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .tertiary,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700)),
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                            ),
                                                          ),
                                                        if (article[index]
                                                                ['description']
                                                            .toString()
                                                            .isNotEmpty)
                                                          Text(
                                                            article[index]
                                                                ['description'],
                                                            style: GoogleFonts.outfit(
                                                                textStyle: TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .tertiary,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400)),
                                                          ),
                                                        Divider(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .tertiary
                                                                  .withOpacity(
                                                                      0.25),
                                                          indent: 50,
                                                          endIndent: 50,
                                                        ),
                                                        RichText(
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: article[
                                                                            index]
                                                                        [
                                                                        'content']
                                                                    .toString()
                                                                    .split(
                                                                        '[+')[0]
                                                                    .trim(),
                                                                style:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  textStyle:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .tertiary,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                recognizer:
                                                                    TapGestureRecognizer()
                                                                      ..onTap =
                                                                          () {
                                                                        _launchUrl(
                                                                            article[index]['url'].toString());
                                                                      },
                                                                text:
                                                                    'Read More',
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            15.5,
                                                                        color: Colors
                                                                            .blue, // Adjust as needed
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w400,
                                                                        decoration:
                                                                            TextDecoration
                                                                                .underline,
                                                                        decorationColor:
                                                                            Colors.blue),
                                                              ),
                                                            ],
                                                          ),
                                                          textAlign:
                                                              TextAlign.justify,
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        (article[index]['urlToImage'] !=
                                                                    'null' &&
                                                                article[index][
                                                                        'urlToImage']
                                                                    .toString()
                                                                    .isNotEmpty)
                                                            ? ClipRRect(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            10)),
                                                                child: Image
                                                                    .network(
                                                                  article[index]
                                                                      [
                                                                      'urlToImage'],
                                                                  fit: BoxFit
                                                                      .fitHeight,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return const SizedBox(); // Display an error icon if image fails to load
                                                                  },
                                                                  loadingBuilder:
                                                                      (context,
                                                                          child,
                                                                          loadingProgress) {
                                                                    if (loadingProgress ==
                                                                        null) {
                                                                      return child; // Image is loaded
                                                                    }
                                                                    return SizedBox(
                                                                      height:
                                                                          150,
                                                                      width:
                                                                          200,
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            SpinKitThreeBounce(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .tertiary,
                                                                          size:
                                                                              40.0,
                                                                        ),
                                                                      ),
                                                                    ); // Show progress indicator
                                                                  },
                                                                ),
                                                              )
                                                            : const SizedBox(
                                                                height: 1,
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Divider(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary,
                                                  )
                                                ],
                                              );
                                            }),
                                      )
                                    : SizedBox(
                                        width: width(context),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/noResult.svg',
                                              width: 250,
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            Text(
                                              'No results found',
                                              style: GoogleFonts.outfit(
                                                textStyle: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                        .withOpacity(.9)),
                                              ),
                                            ),
                                            Text(
                                              'Try shortening or rephrasing your search.',
                                              style: GoogleFonts.outfit(
                                                textStyle: TextStyle(
                                                    fontSize: 15,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                        .withOpacity(.5)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                : connection
                                    ? SizedBox(
                                        child: ListView.builder(
                                            itemCount: 5,
                                            itemBuilder: (context, index) {
                                              return SizedBox(
                                                height: 250,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    SizedBox(
                                                        width: width(context) *
                                                            0.3,
                                                        child:
                                                            LinearProgressIndicator(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      .45),
                                                          borderRadius:
                                                              const BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5)),
                                                          minHeight: 10,
                                                        )),
                                                    const SizedBox(
                                                      height: 15,
                                                    ),
                                                    SizedBox(
                                                        width: width(context) *
                                                            0.4,
                                                        child:
                                                            LinearProgressIndicator(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      .45),
                                                          borderRadius:
                                                              const BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5)),
                                                          minHeight: 5,
                                                        )),
                                                    const SizedBox(
                                                      height: 25,
                                                    ),
                                                    LinearProgressIndicator(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(.45),
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                              Radius.circular(
                                                                  5)),
                                                      minHeight: 15,
                                                    ),
                                                    const SizedBox(
                                                      height: 20,
                                                    ),
                                                    LinearProgressIndicator(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(.45),
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                              Radius.circular(
                                                                  5)),
                                                      minHeight: 12.5,
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    LinearProgressIndicator(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(.45),
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                              Radius.circular(
                                                                  5)),
                                                      minHeight: 12.5,
                                                    ),
                                                    Divider(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                          .withOpacity(0.25),
                                                      indent: 50,
                                                      endIndent: 50,
                                                    ),
                                                    LinearProgressIndicator(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(.45),
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                              Radius.circular(
                                                                  5)),
                                                      minHeight: 10.5,
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    LinearProgressIndicator(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                    .45),
                                                        borderRadius:
                                                            const BorderRadius.all(
                                                                Radius.circular(
                                                                    5)),
                                                        minHeight: 10.5),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    SizedBox(
                                                        width: width(context) *
                                                            0.45,
                                                        child:
                                                            LinearProgressIndicator(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      .45),
                                                          borderRadius:
                                                              const BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          5)),
                                                          minHeight: 10.5,
                                                        )),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Divider(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                          .withOpacity(0.25),
                                                    )
                                                  ],
                                                ),
                                              );
                                            }),
                                      )
                                    : SizedBox(
                                        width: width(context),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/download.png',
                                            ),
                                            Text(
                                              'No Internet Connection',
                                              style: GoogleFonts.outfit(
                                                textStyle: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                        .withOpacity(.9)),
                                              ),
                                            ),
                                            Text(
                                              'Check Your Network, Turn on wifi',
                                              style: GoogleFonts.outfit(
                                                textStyle: TextStyle(
                                                    fontSize: 15,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary
                                                        .withOpacity(.5)),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 30,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  turnOn = true;
                                                  turnOnTheWifi();
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color: turnOn
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(30)),
                                                  border: Border(
                                                      top: BorderSide(
                                                          color: Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(1)),
                                                      bottom: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(1)),
                                                      left: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(1)),
                                                      right: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(1))),
                                                ),
                                                width: width(context) * 0.4,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.wifi,
                                                      size: 30,
                                                      color: !turnOn
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .tertiary,
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    Text(
                                                      'Turn on',
                                                      style: GoogleFonts.outfit(
                                                        textStyle: TextStyle(
                                                            fontSize: 15,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                        visible: speakerContainer,
                        child: GestureDetector(
                            onTap: () async {
                              await flutterTts.stop();
                              setState(() {
                                startIndex = null;
                                endIndex = null;
                                speakerContainer = false;
                              });
                            },
                            child: Container(
                              height: height(context),
                              width: width(context),
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.5),
                            ))),
                    Visibility(
                        visible: speakerContainer,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                color: Theme.of(context).colorScheme.secondary),
                            height: height(context) * .3,
                            child: ListView(
                              children: [
                                Text(
                                  'Description',
                                  style: GoogleFonts.outfit(
                                    textStyle: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: speakWord.substring(0, startIndex),
                                      style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary)),
                                    ),
                                    if (startIndex != null)
                                      TextSpan(
                                        text: speakWord.substring(
                                            startIndex!, endIndex),
                                        style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary),
                                        ),
                                      ),
                                    if (endIndex != null)
                                      TextSpan(
                                        text: speakWord.substring(endIndex!),
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary)),
                                      )
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        )),
                    Visibility(
                      visible: showDragField,
                      child: DraggableScrollableSheet(
                        initialChildSize: 0.36,
                        minChildSize: 0.15,
                        maxChildSize: 0.6,
                        builder: (context, scrollController) => Container(
                          padding: const EdgeInsets.all(10),
                          margin:
                              const EdgeInsets.only(bottom: 15, left: 15, right: 15),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withOpacity(.5),
                                  offset: const Offset(0, 0),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                )
                              ]),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '-----',
                                  style: GoogleFonts.outfit(
                                    textStyle: TextStyle(
                                        letterSpacing: -5,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Select the Area of Interest',
                                  style: GoogleFonts.outfit(
                                    textStyle: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                'Category :',
                                style: GoogleFonts.outfit(
                                  textStyle: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        searchElement[0] = true;
                                        searchElement[1] = false;
                                        searchElement[2] = false;
                                        searchElement[3] = false;
                                        searchElement[4] = false;
                                        customCategory.text = '';
                                        searchArticle = 'Sports';
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: searchElement[0]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              offset: Offset(0, 0),
                                              blurRadius: 15,
                                            )
                                          ]),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 7.5),
                                      child: Text(
                                        'Sports',
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
                                          color: !searchElement[0]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                        )),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        searchElement[0] = false;
                                        searchElement[1] = true;
                                        searchElement[2] = false;
                                        searchElement[3] = false;
                                        customCategory.text = '';
                                        searchArticle = 'Technology';
                                        searchElement[4] = false;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: searchElement[1]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              offset: Offset(0, 0),
                                              blurRadius: 15,
                                            )
                                          ]),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 7.5),
                                      child: Text(
                                        'Technology',
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
                                          color: !searchElement[1]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                        )),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        searchElement[0] = false;
                                        customCategory.text = '';
                                        searchElement[1] = false;
                                        searchElement[2] = true;
                                        searchElement[3] = false;
                                        searchElement[4] = false;
                                        searchArticle = 'Business';
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: searchElement[2]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              offset: Offset(0, 0),
                                              blurRadius: 15,
                                            )
                                          ]),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 7.5),
                                      child: Text(
                                        'Business',
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
                                          color: !searchElement[2]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                        )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        searchElement[0] = false;
                                        customCategory.text = '';
                                        searchElement[1] = false;
                                        searchElement[2] = false;
                                        searchElement[3] = true;
                                        searchElement[4] = false;
                                        searchArticle = 'Health';
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: searchElement[3]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              offset: Offset(0, 0),
                                              blurRadius: 15,
                                            )
                                          ]),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 7.5),
                                      child: Text(
                                        'Health',
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
                                          color: !searchElement[3]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                        )),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        searchElement[0] = false;
                                        customCategory.text = '';
                                        searchElement[1] = false;
                                        searchElement[2] = false;
                                        searchElement[3] = false;
                                        searchElement[4] = true;
                                        searchArticle = 'Entertainment';
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: searchElement[4]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black12,
                                              offset: Offset(0, 0),
                                              blurRadius: 15,
                                            )
                                          ]),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 7.5),
                                      child: Text(
                                        'Entertainment',
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300,
                                          color: !searchElement[4]
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                        )),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 7.5),
                                decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(10)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        offset: Offset(0, 0),
                                        blurRadius: 15,
                                      )
                                    ]),
                                child: TextField(
                                  controller: customCategory,
                                  cursorColor:
                                      Theme.of(context).colorScheme.tertiary,
                                  style: GoogleFonts.outfit(
                                      textStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  )),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: ' Custom Category',
                                    hintStyle: GoogleFonts.outfit(
                                        textStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w300,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    )),
                                  ),
                                  onChanged: (e) {
                                    setState(() {
                                      searchElement[0] = false;
                                      searchElement[1] = false;
                                      searchElement[2] = false;
                                      searchElement[3] = false;
                                      searchElement[4] = false;
                                      searchArticle = customCategory.text;
                                    });
                                  },
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showDragField = false;
                                    getArticle(search: searchArticle);
                                    searchElement[0] = false;
                                    searchElement[1] = false;
                                    searchElement[2] = false;
                                    searchElement[3] = false;
                                    searchElement[4] = false;
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 7.5),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10)),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          offset: Offset(0, 0),
                                          blurRadius: 15,
                                        )
                                      ]),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        'Search',
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w300,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                width: width(context),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 15, top: 5, left: 15, right: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'What\'s New',
                                        style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (connection) {
                                                  allSelected = true;
                                                  showDragField = false;
                                                  searchArticle = '';
                                                  getTopHeadline(countryCode);
                                                } else {
                                                  showToast(
                                                      'Check You Internet');
                                                }
                                              });
                                            },
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 5),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 7.5),
                                              decoration: BoxDecoration(
                                                  color: allSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5)),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      offset: Offset(0, 0),
                                                      blurRadius: 15,
                                                    )
                                                  ]),
                                              child: Text(
                                                'All',
                                                style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w300,
                                                  color: !allSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                )),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (connection) {
                                                  showDragField = true;
                                                  if (!allSelected) {
                                                    allSelected = true;
                                                    showDragField = false;
                                                    getTopHeadline(countryCode);
                                                    searchElement[0] = false;
                                                    searchElement[1] = false;
                                                    searchElement[2] = false;
                                                    searchElement[3] = false;
                                                    searchElement[4] = false;
                                                    searchArticle = '';
                                                  } else {
                                                    allSelected = false;
                                                  }
                                                } else {
                                                  showToast(
                                                      'Check Your Internet');
                                                }
                                              });
                                            },
                                            child: Container(
                                              width: !allSelected ? 120 : 90,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 5),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 7.5),
                                              decoration: BoxDecoration(
                                                  color: !allSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5)),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      offset: Offset(0, 0),
                                                      blurRadius: 15,
                                                    )
                                                  ]),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Search',
                                                    style: GoogleFonts.outfit(
                                                        textStyle: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w300,
                                                      color: allSelected
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .tertiary
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                    )),
                                                  ),
                                                  const SizedBox(
                                                    width: 2,
                                                  ),
                                                  if (!allSelected)
                                                    Icon(
                                                      size: 20,
                                                      Icons.clear,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    )
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (searchArticle.isNotEmpty)
                                            Icon(
                                              Icons.arrow_drop_up_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary,
                                              size: 30,
                                            ),
                                          if (searchArticle.isNotEmpty)
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 5),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 7.5),
                                              decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                          Radius.circular(5)),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      offset: Offset(0, 0),
                                                      blurRadius: 15,
                                                    )
                                                  ]),
                                              child: Text(
                                                searchArticle,
                                                style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w300,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                )),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  DropdownButton<String>(
                                    value: countryCode,
                                    onChanged: (newValue) {
                                      setState(() {
                                        countryCode = newValue!;
                                        searchArticle = '';
                                        allSelected = true;
                                        for (var countryName in countryNames) {
                                          if (countryName['countryCode'] ==
                                              countryCode.toLowerCase()) {
                                            showToast(
                                                'News! from ${countryName['countryName']}');
                                            break;
                                          }
                                        }
                                        getTopHeadline(
                                            countryCode.toLowerCase());
                                      });
                                    },
                                    style: GoogleFonts.outfit(
                                        textStyle: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    )),
                                    dropdownColor:
                                        Theme.of(context).colorScheme.secondary,
                                    borderRadius: const BorderRadius.horizontal(
                                        right: Radius.circular(15)),
                                    menuMaxHeight: 250,
                                    items: countryNames
                                        .map((option) => DropdownMenuItem(
                                              value: option['countryCode'],
                                              child: Text(
                                                option['countryCode']
                                                    .toString()
                                                    .toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w400,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary,
                                                )),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: article.isNotEmpty
                                ? !(article.length == 1 &&
                                        article[0]['article'] == 'Not Article')
                                    ? SizedBox(
                                        height: height(context),
                                        child: ListView.builder(
                                            itemCount: (article.length) + 1,
                                            itemBuilder: (context, index) {
                                              if (index == article.length) {
                                                return SizedBox(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Powered by : ',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          textStyle: TextStyle(
                                                            fontSize: 10,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        'ByteWise Creators',
                                                        style:
                                                            GoogleFonts.outfit(
                                                          textStyle: TextStyle(
                                                            fontSize: 10,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .tertiary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: article[index]
                                                                    ['author']
                                                                .toString()
                                                                .isNotEmpty ||
                                                            article[index][
                                                                    'publishedAt']
                                                                .toString()
                                                                .isNotEmpty
                                                        ? 60
                                                        : 20,
                                                    width: width(context),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            if (article[index]
                                                                    ['author']
                                                                .toString()
                                                                .isNotEmpty)
                                                              SizedBox(
                                                                width: height(
                                                                        context) *
                                                                    0.7,
                                                                height: 20,
                                                                child:
                                                                    TextScroll(
                                                                  article[index]
                                                                      [
                                                                      'author'],
                                                                  mode: TextScrollMode
                                                                      .endless,
                                                                  velocity: const Velocity(
                                                                      pixelsPerSecond:
                                                                          Offset(
                                                                              50,
                                                                              0)),
                                                                  delayBefore:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              50000),
                                                                  pauseBetween:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              2000),
                                                                  style: GoogleFonts.outfit(
                                                                      textStyle: TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .tertiary)),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .right,
                                                                  selectable:
                                                                      true,
                                                                ),
                                                              ),
                                                            if (article[index][
                                                                    'publishedAt']
                                                                .toString()
                                                                .isNotEmpty)
                                                              SizedBox(
                                                                width: height(
                                                                        context) *
                                                                    0.4,
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      article[index]
                                                                              [
                                                                              'publishedAt']
                                                                          .toString()
                                                                          .substring(
                                                                              0,
                                                                              10),
                                                                      style: GoogleFonts.outfit(
                                                                          textStyle: TextStyle(
                                                                              fontSize: 10,
                                                                              color: Theme.of(context).colorScheme.tertiary,
                                                                              fontWeight: FontWeight.w200)),
                                                                    ),
                                                                    Text(
                                                                      '  ||  ',
                                                                      style: GoogleFonts.outfit(
                                                                          textStyle: TextStyle(
                                                                              fontSize: 10,
                                                                              color: Theme.of(context).colorScheme.tertiary,
                                                                              fontWeight: FontWeight.w200)),
                                                                    ),
                                                                    Text(
                                                                      article[index]
                                                                              [
                                                                              'publishedAt']
                                                                          .toString()
                                                                          .substring(
                                                                              11,
                                                                              19),
                                                                      style: GoogleFonts.outfit(
                                                                          textStyle: TextStyle(
                                                                              fontSize: 10,
                                                                              color: Theme.of(context).colorScheme.tertiary,
                                                                              fontWeight: FontWeight.w200)),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        if (article[index]
                                                                ['description']
                                                            .toString()
                                                            .isNotEmpty)
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                speakerContainer =
                                                                    true;
                                                                speakWord = article[
                                                                        index][
                                                                    'description'];
                                                              });
                                                              flutterTts.speak(
                                                                  article[index]
                                                                      [
                                                                      'description']);
                                                            },
                                                            child: Icon(
                                                              Icons
                                                                  .volume_up_rounded,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                            ),
                                                          )
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                width(context) *
                                                                    0.4,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .stretch,
                                                              children: [
                                                                if (article[index]
                                                                        [
                                                                        'title']
                                                                    .toString()
                                                                    .isNotEmpty)
                                                                  SizedBox(
                                                                    height: 35,
                                                                    child:
                                                                        TextScroll(
                                                                      '${article[index]['title']}',
                                                                      mode: TextScrollMode
                                                                          .endless,
                                                                      velocity: const Velocity(
                                                                          pixelsPerSecond: Offset(
                                                                              50,
                                                                              0)),
                                                                      delayBefore:
                                                                          const Duration(
                                                                              milliseconds: 1000),
                                                                      pauseBetween:
                                                                          const Duration(
                                                                              milliseconds: 2000),
                                                                      style: GoogleFonts.outfit(
                                                                          textStyle: TextStyle(
                                                                              fontSize: 15,
                                                                              color: Theme.of(context).colorScheme.tertiary,
                                                                              fontWeight: FontWeight.w700)),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .right,
                                                                    ),
                                                                  ),
                                                                if (article[index]
                                                                        [
                                                                        'description']
                                                                    .toString()
                                                                    .isNotEmpty)
                                                                  Text(
                                                                    article[index]
                                                                        [
                                                                        'description'],
                                                                    style: GoogleFonts.outfit(
                                                                        textStyle: TextStyle(
                                                                            fontSize:
                                                                                13,
                                                                            color:
                                                                                Theme.of(context).colorScheme.tertiary,
                                                                            fontWeight: FontWeight.w400)),
                                                                  ),
                                                                Divider(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .tertiary
                                                                      .withOpacity(
                                                                          0.25),
                                                                  indent: 50,
                                                                  endIndent: 50,
                                                                ),
                                                                RichText(
                                                                  text:
                                                                      TextSpan(
                                                                    children: [
                                                                      TextSpan(
                                                                        text: article[index]['content']
                                                                            .toString()
                                                                            .split('[+')[0]
                                                                            .trim(),
                                                                        style: GoogleFonts
                                                                            .outfit(
                                                                          textStyle:
                                                                              TextStyle(
                                                                            fontSize:
                                                                                11,
                                                                            color:
                                                                                Theme.of(context).colorScheme.tertiary,
                                                                            fontWeight:
                                                                                FontWeight.w400,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      TextSpan(
                                                                        recognizer:
                                                                            TapGestureRecognizer()
                                                                              ..onTap = () {
                                                                                _launchUrl(article[index]['url'].toString());
                                                                              },
                                                                        text:
                                                                            'Read More',
                                                                        style: const TextStyle(
                                                                            fontSize: 15.5,
                                                                            color: Colors.blue, // Adjust as needed
                                                                            fontWeight: FontWeight.w400,
                                                                            decoration: TextDecoration.underline,
                                                                            decorationColor: Colors.blue),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .justify,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                        ],
                                                      ),
                                                      (article[index]['urlToImage'] !=
                                                                  'null' &&
                                                              article[index][
                                                                      'urlToImage']
                                                                  .toString()
                                                                  .isNotEmpty)
                                                          ? SizedBox(
                                                              width: width(
                                                                      context) *
                                                                  0.33,
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                        Radius.circular(
                                                                            10)),
                                                                child: Image
                                                                    .network(
                                                                  article[index]
                                                                      [
                                                                      'urlToImage'],
                                                                  fit: BoxFit
                                                                      .fitWidth,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return const SizedBox(); // Display an error icon if image fails to load
                                                                  },
                                                                  loadingBuilder:
                                                                      (context,
                                                                          child,
                                                                          loadingProgress) {
                                                                    if (loadingProgress ==
                                                                        null) {
                                                                      return child; // Image is loaded
                                                                    }
                                                                    return SizedBox(
                                                                      width: width(
                                                                              context) *
                                                                          0.3,
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            SpinKitThreeBounce(
                                                                          color: Theme.of(context)
                                                                              .colorScheme
                                                                              .tertiary,
                                                                          size:
                                                                              40.0,
                                                                        ),
                                                                      ),
                                                                    ); // Show progress indicator
                                                                  },
                                                                ),
                                                              ),
                                                            )
                                                          : SizedBox(
                                                              child: Text(
                                                                'Now Images\nAbout this Article',
                                                                style: GoogleFonts.outfit(
                                                                    textStyle: TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                        color: Theme.of(context)
                                                                            .colorScheme
                                                                            .tertiary,
                                                                        fontWeight:
                                                                            FontWeight.w400)),
                                                              ),
                                                            )
                                                    ],
                                                  ),
                                                  Divider(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .tertiary,
                                                  )
                                                ],
                                              );
                                            }),
                                      )
                                    : SizedBox(
                                        width: width(context),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/noResult.svg',
                                              width: 250,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'No results found',
                                                  style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary
                                                            .withOpacity(.9)),
                                                  ),
                                                ),
                                                Text(
                                                  'Try shortening or rephrasing your search.',
                                                  style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary
                                                            .withOpacity(.5)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                : connection
                                    ? SizedBox(
                                        child: ListView.builder(
                                            itemCount: 5,
                                            itemBuilder: (context, index) {
                                              return SizedBox(
                                                height: 250,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        SizedBox(
                                                          width:
                                                              width(context) *
                                                                  0.4,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              SizedBox(
                                                                  width: width(
                                                                          context) *
                                                                      0.1,
                                                                  child:
                                                                      LinearProgressIndicator(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    backgroundColor: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withOpacity(
                                                                            .45),
                                                                    borderRadius:
                                                                        const BorderRadius.all(
                                                                            Radius.circular(5)),
                                                                    minHeight:
                                                                        10,
                                                                  )),
                                                              const SizedBox(
                                                                height: 15,
                                                              ),
                                                              SizedBox(
                                                                  width: width(
                                                                          context) *
                                                                      0.2,
                                                                  child:
                                                                      LinearProgressIndicator(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    backgroundColor: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withOpacity(
                                                                            .45),
                                                                    borderRadius:
                                                                        const BorderRadius.all(
                                                                            Radius.circular(5)),
                                                                    minHeight:
                                                                        5,
                                                                  )),
                                                              const SizedBox(
                                                                height: 25,
                                                              ),
                                                              LinearProgressIndicator(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                backgroundColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        .45),
                                                                borderRadius: const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5)),
                                                                minHeight: 15,
                                                              ),
                                                              const SizedBox(
                                                                height: 20,
                                                              ),
                                                              LinearProgressIndicator(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                backgroundColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        .45),
                                                                borderRadius: const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5)),
                                                                minHeight: 12.5,
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              LinearProgressIndicator(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                backgroundColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        .45),
                                                                borderRadius: const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5)),
                                                                minHeight: 12.5,
                                                              ),
                                                              Divider(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .tertiary
                                                                    .withOpacity(
                                                                        0.25),
                                                                indent: 50,
                                                                endIndent: 50,
                                                              ),
                                                              LinearProgressIndicator(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                backgroundColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        .45),
                                                                borderRadius: const BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            5)),
                                                                minHeight: 10.5,
                                                              ),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              LinearProgressIndicator(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary,
                                                                  backgroundColor: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                          .45),
                                                                  borderRadius:
                                                                      const BorderRadius.all(
                                                                          Radius.circular(
                                                                              5)),
                                                                  minHeight:
                                                                      10.5),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              SizedBox(
                                                                  width: width(
                                                                          context) *
                                                                      0.45,
                                                                  child:
                                                                      LinearProgressIndicator(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                    backgroundColor: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary
                                                                        .withOpacity(
                                                                            .45),
                                                                    borderRadius:
                                                                        const BorderRadius.all(
                                                                            Radius.circular(5)),
                                                                    minHeight:
                                                                        10.5,
                                                                  )),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          child: Center(
                                                            child:
                                                                SpinKitThreeBounce(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary,
                                                              size: 40.0,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 20,
                                                        )
                                                      ],
                                                    ),
                                                    Divider(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .tertiary
                                                          .withOpacity(0.25),
                                                    )
                                                  ],
                                                ),
                                              );
                                            }),
                                      )
                                    : SizedBox(
                                        width: width(context),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/download.png',
                                              height: 200,
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'No Internet Connection',
                                                  style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary
                                                            .withOpacity(.9)),
                                                  ),
                                                ),
                                                Text(
                                                  'Check Your Network, Turn on wifi',
                                                  style: GoogleFonts.outfit(
                                                    textStyle: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .tertiary
                                                            .withOpacity(.5)),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      turnOn = true;
                                                      turnOnTheWifi();
                                                    });
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: turnOn
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                              Radius.circular(
                                                                  30)),
                                                      border: Border(
                                                          top: BorderSide(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      1)),
                                                          bottom: BorderSide(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      1)),
                                                          left: BorderSide(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      1)),
                                                          right: BorderSide(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(1))),
                                                    ),
                                                    width: width(context) * 0.2,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.wifi,
                                                          size: 30,
                                                          color: !turnOn
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .tertiary,
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
                                                          'Turn on',
                                                          style: GoogleFonts
                                                              .outfit(
                                                            textStyle: TextStyle(
                                                                fontSize: 15,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .tertiary),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                        visible: speakerContainer,
                        child: GestureDetector(
                            onTap: () async {
                              await flutterTts.stop();
                              setState(() {
                                startIndex = null;
                                endIndex = null;
                                speakerContainer = false;
                              });
                            },
                            child: Container(
                              height: height(context),
                              width: width(context),
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.5),
                            ))),
                    Visibility(
                        visible: speakerContainer,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                color: Theme.of(context).colorScheme.secondary),
                            height: height(context) * .6,
                            width: width(context) * 0.5,
                            child: ListView(
                              children: [
                                Text(
                                  'Description',
                                  style: GoogleFonts.outfit(
                                    textStyle: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                      text: speakWord.substring(0, startIndex),
                                      style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary)),
                                    ),
                                    if (startIndex != null)
                                      TextSpan(
                                        text: speakWord.substring(
                                            startIndex!, endIndex),
                                        style: GoogleFonts.outfit(
                                          textStyle: TextStyle(
                                              fontSize: 18,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .tertiary,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary),
                                        ),
                                      ),
                                    if (endIndex != null)
                                      TextSpan(
                                        text: speakWord.substring(endIndex!),
                                        style: GoogleFonts.outfit(
                                            textStyle: TextStyle(
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .tertiary)),
                                      )
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        )),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Visibility(
                        visible: showDragField,
                        child: DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.72,
                          minChildSize: 0.3,
                          maxChildSize: 0.85,
                          builder: (context, scrollController) => Container(
                            width: height(context) * 0.8,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(
                                bottom: 15, left: 15, right: 15),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary
                                        .withOpacity(.5),
                                    offset: const Offset(0, 0),
                                    blurRadius: 50,
                                    spreadRadius: 5,
                                  )
                                ]),
                            child: ListView(
                              controller: scrollController,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '-----',
                                    style: GoogleFonts.outfit(
                                      textStyle: TextStyle(
                                          letterSpacing: -5,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Select the Area of Interest',
                                    style: GoogleFonts.outfit(
                                      textStyle: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiary),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Category :',
                                  style: GoogleFonts.outfit(
                                    textStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchElement[0] = true;
                                          searchElement[1] = false;
                                          searchElement[2] = false;
                                          searchElement[3] = false;
                                          searchElement[4] = false;
                                          customCategory.text = '';
                                          searchArticle = 'Sports';
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: searchElement[0]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20)),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 0),
                                                blurRadius: 15,
                                              )
                                            ]),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 7.5),
                                        child: Text(
                                          'Sports',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                            color: !searchElement[0]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                          )),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchElement[0] = false;
                                          searchElement[1] = true;
                                          searchElement[2] = false;
                                          searchElement[3] = false;
                                          customCategory.text = '';
                                          searchArticle = 'Technology';
                                          searchElement[4] = false;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: searchElement[1]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20)),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 0),
                                                blurRadius: 15,
                                              )
                                            ]),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 7.5),
                                        child: Text(
                                          'Technology',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                            color: !searchElement[1]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                          )),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchElement[0] = false;
                                          customCategory.text = '';
                                          searchElement[1] = false;
                                          searchElement[2] = true;
                                          searchElement[3] = false;
                                          searchElement[4] = false;
                                          searchArticle = 'Business';
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: searchElement[2]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20)),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 0),
                                                blurRadius: 15,
                                              )
                                            ]),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 7.5),
                                        child: Text(
                                          'Business',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                            color: !searchElement[2]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                          )),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchElement[0] = false;
                                          customCategory.text = '';
                                          searchElement[1] = false;
                                          searchElement[2] = false;
                                          searchElement[3] = true;
                                          searchElement[4] = false;
                                          searchArticle = 'Health';
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: searchElement[3]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20)),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 0),
                                                blurRadius: 15,
                                              )
                                            ]),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 7.5),
                                        child: Text(
                                          'Health',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                            color: !searchElement[3]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                          )),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          searchElement[0] = false;
                                          customCategory.text = '';
                                          searchElement[1] = false;
                                          searchElement[2] = false;
                                          searchElement[3] = false;
                                          searchElement[4] = true;
                                          searchArticle = 'Entertainment';
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            color: searchElement[4]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20)),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black12,
                                                offset: Offset(0, 0),
                                                blurRadius: 15,
                                              )
                                            ]),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 7.5),
                                        child: Text(
                                          'Entertainment',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300,
                                            color: !searchElement[4]
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .tertiary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                          )),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      showDragField = false;
                                      getArticle(search: searchArticle);
                                      searchElement[0] = false;
                                      searchElement[1] = false;
                                      searchElement[2] = false;
                                      searchElement[3] = false;
                                      searchElement[4] = false;
                                    });
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 7.5),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(10)),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            offset: Offset(0, 0),
                                            blurRadius: 15,
                                          )
                                        ]),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          'Search',
                                          style: GoogleFonts.outfit(
                                              textStyle: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w300,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          )),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri toLaunch = Uri.parse(url);
    if (!await launchUrl(
      toLaunch,
      mode: LaunchMode.inAppWebView,
    )) {
      showToast('Something went wrong');
      throw Exception('Could not launch $url');
    }
  }

  getData() async {
    await getArticle();
  }

  turnOnTheWifi() async {
    await SystemShortcuts.wifi();
  }
}
