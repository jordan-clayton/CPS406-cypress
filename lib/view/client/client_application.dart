import 'dart:developer';

import 'package:cypress/view/client/routes/home_screen.dart';
import 'package:flutter/material.dart';

import '../../app/client/client_controller.dart';
import '../common/routes/error_screen.dart';
import '../common/routes/loading_screen.dart';

class ClientApplication extends StatefulWidget {
  const ClientApplication({super.key, required this.initializeController});

  final Future<ClientController> initializeController;

  @override
  State<ClientApplication> createState() => _ClientApplicationState();
}

class _ClientApplicationState extends State<ClientApplication> {
  late Future<ClientController> _initController;
  @override
  initState() {
    super.initState();
    _initController = widget.initializeController;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Cypress',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: FutureBuilder(
            future: _initController,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingScreen();
              }
              // If there's no data, something went very wrong
              if (!snapshot.hasData) {
                return ErrorScreen(
                  errorMessage: 'No controller loaded',
                  // This will force a rebuild of the future to try and restart the application.
                  recoveryFunction: () => setState(() {
                    _initController = widget.initializeController;
                  }),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error!;
                log('Controller future encountered an error when loading: ${error.toString()}',
                    error: error, stackTrace: snapshot.stackTrace);
                return ErrorScreen(
                  errorMessage: 'Error loading controller',
                  recoveryFunction: () => setState(() {}),
                );
              }

              return HomeScreen(
                controller: snapshot.data!,
              );
            }));
  }
}
