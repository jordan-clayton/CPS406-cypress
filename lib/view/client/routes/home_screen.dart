import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';
import '../../common/widgets/floating_menu_button.dart';
import '../widgets/map_report_viewer.dart';

/// A basic scaffold containing the map, a floating action button to make reports
/// If the client is not registered/logged in, push to the sign in/log in screen
/// If the client is registered, push to the report form screen
/// In all routing, pass the controller as an argument to the page generator
/// Use a dictionary to encapsulate any objects that need to persist

// TODO: periodic refresh/app recycle state refresh.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final ClientController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// TODO: this will need a navigation drawer.
// The navigation drawer should allow navigation to the login screen/sign up screen.
// TODO: finish FAB.
class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(children: [
          const FloatingMenuButton(),
          ReportViewerMap(
              controller: widget.controller,
              handleError: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  var errorBar = SnackBar(
                    content: const Text('Error retrieving new reports.'),
                    action: SnackBarAction(
                        label: 'Retry?', onPressed: () => setState(() {})),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(errorBar);
                });
              }),
        ]),
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
      ),
    );
  }
}
