import 'dart:developer';

import 'package:flutter/material.dart';

import '../../app/client/employee_controller.dart';
import '../common/routes/error_screen.dart';
import '../common/routes/loading_screen.dart';
import 'routes/home_screen.dart';


class EmployeeApplication extends StatefulWidget {
  const EmployeeApplication({super.key, required this.initializeController});

  final Future<EmployeeController> initializeController;

  @override
  State<EmployeeApplication> createState() => _EmployeeApplicationState();
}

class _EmployeeApplicationState extends State<EmployeeApplication> {
  late Future<EmployeeController> _initController;
  // This needs to persist across rebuilds.
  late final RouteObserver<ModalRoute<void>> _routeObserver;
  @override
  initState() {
    super.initState();
    _routeObserver = RouteObserver();
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
        navigatorObservers: [_routeObserver],
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
                  recoveryFunction: () => setState(() {
                    _initController = widget.initializeController;
                  }),
                );
              }

              return HomeScreen(
                controller: snapshot.data!,
                routeObserver: _routeObserver,
              );
            }));
  }
}
