import 'package:flutter/material.dart';
import 'contants/colors_constants.dart';
import 'weather_module/weather.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Weather App',
        home: const MyHomePageApp(title: 'Weather App'));
  }
}

class MyHomePageApp extends StatefulWidget {
  const MyHomePageApp({super.key, required this.title});
  final String title;
  @override
  State<MyHomePageApp> createState() => _MyHomePageApp();
}

class _MyHomePageApp extends State<MyHomePageApp> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    firstAppbarColor,
                    secondAppbarColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: Center(
              child: Text("Weather App", style: TextStyle(color: titleColor)),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.wb_sunny, color: titleColor),
                onPressed: null,
              ),
            ],
          ),
          body: WeatherScreen()),
    );
  }
}
