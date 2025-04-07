import 'dart:io';

import 'package:cypress/view/client/routes/report_form_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';
import '../../common/widgets/floating_menu_button.dart';
import '../widgets/map_report_viewer.dart';
import 'login_screen.dart';

/// A basic scaffold containing the map, a floating action button to make reports
/// If the client is not registered/logged in, push to the sign in/log in screen
/// If the client is registered, push to the report form screen
/// In all routing, pass the controller as an argument to the page generator

// TODO: periodic refresh/app recycle state refresh.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final ClientController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: _loading guard against grandma clicks.
  @override
  Widget build(BuildContext context) {
    bool apple = Platform.isMacOS || Platform.isIOS;
    return PopScope(
      canPop: false,
      child: Scaffold(
        // TODO: finish drawer.
        // The navigation drawer should allow navigation to the login screen/sign up screen.
        drawer: Drawer(),
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
              return FloatingActionButton(
                  child: (loggedIn)
                      ? const Icon(Icons.report_problem_outlined)
                      : const Icon(Icons.login_rounded),
                  onPressed: () async {
                    if (loggedIn) {
                      // Route to Report filing page
                      await Navigator.push(
                          context,
                          (apple)
                              ? CupertinoPageRoute(
                                  builder: (context) => ReportFormScreen(
                                      controller: widget.controller))
                              : MaterialPageRoute(
                                  builder: (context) => ReportFormScreen(
                                      controller: widget.controller)));
                    } else {
                      await Navigator.push(
                          context,
                          (apple)
                              ? CupertinoPageRoute(
                                  builder: (context) => LoginScreen(
                                      controller: widget.controller))
                              : MaterialPageRoute(
                                  builder: (context) => LoginScreen(
                                      controller: widget.controller)));
                    }
                  });
            }),
      ),
    );
  }
}
