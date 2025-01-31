import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/contants/colors_constants.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  List<Map<String, String>> cachedCitiesWeather = [];
  static const String apiKey = '8e63b47b0fcc06554b17dd9de77e254a';
  String weather = "";
  bool update = false;
  String currentWeather = "";
  bool isCelsius = true;
  bool isLoading = false;
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      //For clearing database when app is intalled for the First Time
      await _clearCacheOnFirstLaunch();
      _checkLocationServices();
    });
    _loadCachedCitiesWeather();
    _loadCachedWeather();
  }

  // Clears cache on first app launch
  Future<void> _clearCacheOnFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool("is_first_launch") ?? true;
    if (isFirstLaunch) {
      await prefs.remove("cached_weather");
      await prefs.remove("cached_cities_weather");
      await prefs.setBool("is_first_launch", false);
    }
  }

  // Loads cached weather data for searched cities
  Future<void> _loadCachedCitiesWeather() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedCities = prefs.getString("cached_cities_weather");
    if (cachedCities != null) {
      List<Map<String, String>> citiesWeather = List<Map<String, String>>.from(
          json.decode(cachedCities).map((x) => Map<String, String>.from(x)));
      setState(() {
        cachedCitiesWeather = citiesWeather;
      });
    }
  }

  // Caches the searched cities weather data
  Future<void> _cacheCitiesWeather() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = json.encode(cachedCitiesWeather);
    await prefs.setString("cached_cities_weather", jsonData);
  }

  // Checks if location services are enabled
  Future<void> _checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    int attempts = 0;
    while (!serviceEnabled && attempts < 3) {
      await Future.delayed(Duration(seconds: 1));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      attempts++;
    }

    if (!serviceEnabled) {
      _showLocationServicesDialog();
    } else {
      _requestLocationPermission();
    }
  }

  // Requests location permissions from the user
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        weather = "Location permission permanently denied.";
      });
    } else {
      _fetchWeather();
    }
  }

  // Displays a dialog if location services are disabled
  void _showLocationServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Services Disabled"),
        content: Text("Please enable location services to fetch weather data."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (serviceEnabled) {
                _requestLocationPermission();
              }
              _checkLocationServices();
            },
            child: Text("Enable Location"),
          ),
        ],
      ),
    );
  }

  // Loads cached weather for the current location
  Future<void> _loadCachedWeather() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedWeather = prefs.getString("cached_weather");
    if (cachedWeather != null) {
      setState(() {
        weather = cachedWeather;
      });
    } else {
      setState(() {
        weather = "Enable location services to fetch weather.";
      });
    }
  }

  // Caches weather data
  Future<void> _cacheWeather(String data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("cached_weather", data);
  }

  // Fetches weather data from the API
  Future<void> _fetchWeather() async {
    String city = _cityController.text.trim();
    setState(() {
      isLoading = true;
    });

    Position? position;
    if (city.isEmpty) {
      try {
        position = await _determinePosition();
      } catch (e) {
        setState(() {
          _loadCachedWeather();
          isLoading = false;
        });
        return;
      }
    }

    String url = city.isNotEmpty
        ? 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric'
        : 'https://api.openweathermap.org/data/2.5/weather?lat=${position!.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';

    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        double temperature = (data['main']['temp'] as num).toDouble();
        int humidity = data['main']['humidity'] ?? 0;
        double windSpeed = data['wind']['speed'] ?? 0.0;

        if (!isCelsius) {
          temperature = (temperature * 9 / 5) + 32;
        }

        String weatherData =
            "${temperature.toStringAsFixed(1)}° ${isCelsius ? 'C' : 'F'}, Humidity: $humidity%, Wind: $windSpeed m/s";

        setState(() {
          weather = weatherData;
        });
        if (city.isEmpty) {
          _cacheWeather(weatherData);
        } else {
          cachedCitiesWeather.removeWhere((item) => item["city"] == city);
          cachedCitiesWeather.add({
            "city": city,
            "temperature": temperature.toStringAsFixed(1),
            "humidity": humidity.toString(),
            "windSpeed": windSpeed.toString(),
          });
          _cacheCitiesWeather();
        }
      } else {
        setState(() {
          update = false;
          for (int i = 0; i < cachedCitiesWeather.length; i++) {
            if (cachedCitiesWeather[i]["city"] == city) {
              weather =
                  "${cachedCitiesWeather[i]["temperature"]}° ${isCelsius ? 'C' : 'F'}, Humidity: ${cachedCitiesWeather[i]["humidity"]}%, Wind: ${cachedCitiesWeather[i]["windSpeed"]} m/s";
              setState(() {
                update = true;
              });
              break;
            }
          }

          if (update == false) {
            weather = "Failed to fetch weather data";
          }
        });
      }
    } catch (e) {
      setState(() {
        update = false;

        for (int i = 0; i < cachedCitiesWeather.length; i++) {
          if (cachedCitiesWeather[i]["city"] == city) {
            weather =
                "${cachedCitiesWeather[i]["temperature"]}° ${isCelsius ? 'C' : 'F'}, Humidity: ${cachedCitiesWeather[i]["humidity"]}%, Wind: ${cachedCitiesWeather[i]["windSpeed"]} m/s";
            setState(() {
              update = true;
            });
            break;
          }
        }

        if (update == false) {
          weather = "Failed to fetch weather data";
        }
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Determmines current location coordinates
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // For Switching data between Celcius and Farenhite
  void _toggleUnit() {
    setState(() {
      isCelsius = !isCelsius;
    });
    _fetchWeather();
  }

//Displayed User Interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [titleColor, bodyColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 18.0, top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "°C",
                      style: TextStyle(
                        fontSize: 16,
                        color: celsius,
                        fontWeight:
                            isCelsius ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: !isCelsius,
                        onChanged: (value) {
                          _toggleUnit();
                        },
                        activeTrackColor: switchActiveTrackColor,
                        inactiveThumbColor: switchActiveTrackColor,
                        inactiveTrackColor: titleColor,
                        activeColor: appbarTextColor,
                      ),
                    ),
                    Text(
                      "°F",
                      style: TextStyle(
                        color: celsius,
                        fontSize: 16,
                        fontWeight:
                            !isCelsius ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  "Current Weather",
                  style: TextStyle(fontSize: 35, color: celsius),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                alignment: Alignment.center,
                child: Image.asset(
                  "./images/clls.png",
                  height: 120,
                  width: 120,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              if (isLoading) CircularProgressIndicator(),
              if (!isLoading) ...[
                Center(
                  child: SizedBox(
                      width: 250,
                      child: Text(weather,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18))),
                ),
              ],
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 28.0, left: 15, right: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: titleColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 6,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _cityController,
                    onChanged: (value) {
                      setState(() {
                        weather = '';
                      });
                      if (value.isEmpty) {
                        _fetchWeather();
                      } else if (value.isNotEmpty) {
                        setState(() {});
                        isLoading = false;
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter City Name',
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon:
                          Icon(Icons.location_city, color: locationColor),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: searchColor),
                        onPressed: _fetchWeather,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: borderSideColor, width: 2),
                      ),
                      filled: true,
                      fillColor: titleColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(top: 38.0),
                child: ElevatedButton(
                  onPressed: _fetchWeather,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: titleColor,
                    foregroundColor: appbarTextColor,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Fetch Weather Data"),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
