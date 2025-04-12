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
- Web

## Features

### Citizen-facing application
Users can use the Cypress app to view information about current City-wide emergencies and problems
on an intuitive (hopefully), interactive map in real time. They may optionally register for an account to be able to file
new report tickets with the city. Good-natured citizens can also moderate by flagging duplicate and
malicious reports to the city.

### Employee-facing application
For City of Toronto employees. Authenticated users can use the GUI to view incoming reports, as well
as monitor and update the progress of currently open reports.
A suite of tools is provided for software-assisted verification and validation, and measuring duplicate reports.

The project in its current iteration uses Supabase to host its backend database.

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
- Test suite implementation
- GUI for internal City of Toronto use

### Roadmap
- Client accessible report list views and sorting.

## Building
### Dependencies:
- [Flutter](https://docs.flutter.dev/get-started/install) 

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

And then rebuild the project

### Building the employee application

If you have not grabbed dependencies, run:

`flutter pub get`

To run the employee app (in debug mode) run the following command prompt:

`flutter run -t lib/employee.dart`

To build the employee exectuable in release mode, run the following:

`flutter build <your platform> -t lib/employee.dart --release`

If you encounter issues building the project, try running:

`flutter clean && flutter pub get`

And then rebuild the project
