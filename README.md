# Cypress: CPS 406 Intro to Software Engineering Project

A real-time issue reporting and tracking system for the City of Toronto

## Team Members:

- Jordan Clayton: 501201305
- Suchana Regmi: 501173160
- Rizoan Azfar: 501237799
- Suhaib Khan: 501112462
- Dhan Payos 501248203

## Supported Platforms:

- Windows
- MacOS
- Linux
- Android
- iOS

## Features

### Implemented

- GUI for users to view issues in real time on an intuitive map
- Heuristics to automate flagging duplicate reports internally
- Location-services to assist with geolocation during reporting
- Database API for maintaining records of all tracked issues
- Integration with a server backend
- Reporting API for submitting new City issues to track
- Subscription API to allow users to track report updates
- User-led moderation API to allow users to flag duplicates and malicious reports
- Client and Internal application controller APIs to interact with the system

### Roadmap

- Test suite implementation and integration
- GUI for internal City of Toronto use

## Building
### Dependencies:
- [Flutter](https://docs.flutter.dev/get-started/install) 

**NOTE: presently the application does not support Flutter Web. Do not try to build for for flutter
web.**

First, grab dependencies with:

`flutter pub get`

To run the client app (in debug mode), run the following command prompt:

`flutter run`

Select your preferred (connected) device and wait for the project to build and launch.
Tack --release to run the application in release mode.

To build the client executable in release mode, run the following:

`flutter build <your platform> --release`

(eg. windows, macos, ios, apk, etc.)
Wait for the project to compile and the final executable will be in build/release/your_platform/

If you encounter issues building the project, try running:

`flutter clean && flutter pub get`

At this time, the internal application is not implemented. Instructions
for building will follow once the solution exists.
