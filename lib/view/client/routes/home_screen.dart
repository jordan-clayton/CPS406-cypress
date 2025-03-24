import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';

/// A basic scaffold containing the map, a floating action button to make reports
/// If the client is not registered/logged in, push to the sign in/log in screen
/// If the client is registered, push to the report form screen
/// In all routing, pass the controller as an argument to the page generator
/// Use a dictionary to encapsulate any objects that need to persist
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final ClientController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// TODO: this will need a navigation drawer and hamburger button.
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('map here pls.')),
      floatingActionButton: ValueListenableBuilder(
          valueListenable: widget.controller.loggedIn,
          builder: (context, loggedIn, child) {
            if (loggedIn) {
              // Push context to report-making screen
            }
            // Push context to log-in screen
            // TODO: finish
            throw UnimplementedError();
          }),
    );
  }
}
