import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';

// We might be able to get away with stateless widgets.
// The ValueListenablebuilder is itself stateful.
class LoginScreen extends StatefulWidget {
  // Note: this cannot be const; the controller is heap-allocated
  LoginScreen({super.key, required this.controller});

  final ClientController controller;

  @override
  State<LoginScreen> createState() => _LoginFormScreenState();
}

// Basic design: A very simple login screen with two fields, one for username,
// one for password. The first button below the text fields should be the login button
// The second one should be the sign up button

// Call validation functions on an attempt to log in and respond accordingly.
// Set the _loggingIn valueNotifier when logging in to prevent grandma-clicks

// Await the controller's login method before popping the context.
// Wait some time after the context pop before restoring the loggingIn function
// On an error, catch it and display a snackbar.

// The sign up button should Pop the context and then push to the Sign-up screen
// (Or just push the Sign-up screen and let the user navigate back)

class _LoginFormScreenState extends State<LoginScreen> {
  final ValueNotifier<bool> _loggingIn = ValueNotifier(false);
  // TODO: textcontrollers
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
