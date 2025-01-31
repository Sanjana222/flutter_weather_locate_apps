# flutter_application_1

A new Flutter project.

This is a weather app built with Flutter. It helps you find out the weather for any city. You can either see the weather for your current location (using your phone's location services) or search for the weather in any city by typing its name.

The app remembers weather information for cities you’ve checked before, so even if you don’t have an internet connection, it can show you the weather from its memory. You can also switch between Celsius (°C) and Fahrenheit (°F) to see the temperature in the unit you prefer.

## Prerequisites

To run this project, you need to have the following tools installed:

- Flutter SDK (preferably the latest stable version)
- Dart SDK (comes with Flutter)
- Any IDE supporting Flutter (VS Code, Android Studio)

## Installation

Clone the repository:
   git clone https://github.com/Sanjana222/flutter_weather_locate_apps.git

### Android Configuration [Just for Information]

- I have added permissions for accessing location services in `AndroidManifest.xml`:
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-feature android:name="android.hardware.location.gps"/>

### iOS Configuration [Just for Information]
- I have added location permissions in `Info.plist`:
<key>NSLocationWhenInUseUsageDescription</key>


## Run App
After cloning Repository, type in terminal cd flutter_weather_locate_apps
Clean the project by flutter clean
Get Packages by flutter pub get
Run the project by flutter run

