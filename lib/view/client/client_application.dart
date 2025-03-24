import 'dart:developer';

import 'package:cypress/view/client/routes/home_screen.dart';
import 'package:flutter/material.dart';

import '../../app/client/client_controller.dart';
import '../common/routes/error_screen.dart';
import '../common/routes/loading_screen.dart';

// NOTE: try to minimize the amount of state required to be maintained across
// the application.

// So far, the set up is to pass the controller to screens that need it
// The same applies for data; most of it doesn't need to be stored and can be
// maintained using functions/constructors.

/// The base (client) application.
/// Arguments: initializeController, a future that's called on first build
/// to initialize the app. Shows the loading screen while the future completes.
class ClientApplication extends StatelessWidget {
  const ClientApplication({super.key, required this.initializeController});

  final Future<ClientController> initializeController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Cypress',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FutureBuilder<ClientController>(
            future: initializeController,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingScreen();
              }
              // If there's no data, something went very wrong
              if (!snapshot.hasData) {
                return ErrorScreen(errorMessage: 'No controller loaded');
              }

              if (snapshot.hasError) {
                final error = snapshot.error!;
                log('Controller future encountered an error when loading: ${error.toString()}',
                    error: error, stackTrace: snapshot.stackTrace);
                return ErrorScreen(errorMessage: 'Error loading controller');
              }

              return HomeScreen(
                controller: snapshot.data!,
              );
            }));
  }
}
