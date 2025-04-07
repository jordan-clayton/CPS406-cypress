import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
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
  late ValueNotifier<bool> _loading;

  @override
  initState() {
    super.initState();
    _loading = ValueNotifier(false);
  }

  @override
  Widget build(BuildContext context) {
    bool apple = Platform.isMacOS || Platform.isIOS;
    return PopScope(
      canPop: false,
      child: ValueListenableBuilder(
          valueListenable: widget.controller.loggedIn,
          builder: (context, loggedIn, child) {
            return Scaffold(
              drawer: Drawer(
                child: ListView(children: [
                  const DrawerHeader(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Text('Cypress')]),
                  ),
                  (loggedIn)
                      ? ListTile(
                          title: const Text('User Settings'),
                          onTap: () async {
                            // Pop the drawer.
                            Navigator.pop(context);
                            await showOkAlertDialog(
                                context: this.context,
                                title: 'Coming Soon',
                                message: 'Feature not yet implemented');
                          })
                      : ListTile(
                          title: const Text('Log In'),
                          onTap: () async {
                            // Pop the drawer and route to the login page
                            Navigator.pop(context);
                            _loading.value = true;
                            Navigator.push(
                                this.context,
                                (apple)
                                    ? CupertinoPageRoute(
                                        builder: (context) => LoginScreen(
                                            controller: widget.controller))
                                    : MaterialPageRoute(
                                        builder: (context) => LoginScreen(
                                            controller: widget.controller)));
                          })
                ]),
              ),
              body: Stack(children: [
                const FloatingMenuButton(),
                ReportViewerMap(
                    controller: widget.controller,
                    handleError: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        var errorBar = SnackBar(
                          content: const Text('Error retrieving new reports.'),
                          action: SnackBarAction(
                              label: 'Retry?',
                              onPressed: () => setState(() {})),
                        );
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(errorBar);
                      });
                    }),
              ]),
              floatingActionButton: ValueListenableBuilder(
                  valueListenable: _loading,
                  builder: (context, loading, child) {
                    return FloatingActionButton(
                        onPressed: (loading)
                            ? null
                            : () async {
                                if (loggedIn) {
                                  // Route to Report filing page
                                  _loading.value = true;
                                  await Navigator.push(
                                      this.context,
                                      (apple)
                                          ? CupertinoPageRoute(
                                              builder: (context) =>
                                                  ReportFormScreen(
                                                      controller:
                                                          widget.controller))
                                          : MaterialPageRoute(
                                              builder: (context) =>
                                                  ReportFormScreen(
                                                      controller:
                                                          widget.controller)));
                                  await Future.delayed(
                                          const Duration(milliseconds: 200))
                                      .then((_) => _loading.value = false);
                                } else {
                                  _loading.value = true;
                                  await Navigator.push(
                                      this.context,
                                      (apple)
                                          ? CupertinoPageRoute(
                                              builder: (context) => LoginScreen(
                                                  controller:
                                                      widget.controller))
                                          : MaterialPageRoute(
                                              builder: (context) => LoginScreen(
                                                  controller:
                                                      widget.controller)));
                                  await Future.delayed(
                                          const Duration(milliseconds: 200))
                                      .then((_) => _loading.value = false);
                                }
                              },
                        child: (loading)
                            ? const CircularProgressIndicator.adaptive()
                            : (loggedIn)
                                ? const Icon(Icons.report_problem_outlined)
                                : const Icon(Icons.login_rounded));
                  }),
            );
          }),
    );
  }
}
