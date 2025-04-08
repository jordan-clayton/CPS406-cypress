import 'dart:async';
import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';
import '../../common/widgets/floating_menu_button.dart';
import '../widgets/map_report_viewer.dart';
import 'login_screen.dart';
import 'report_form_screen.dart';

/// A basic scaffold containing the map, a floating action button to make reports
/// If the client is not registered/logged in, push to the sign in/log in screen
/// If the client is registered, push to the report form screen
/// In all routing, pass the controller as an argument to the page generator

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key, required this.controller, required this.routeObserver});

  final ClientController controller;
  final RouteObserver<ModalRoute<void>> routeObserver;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  late ValueNotifier<bool> _loading;
  late Timer _queryTimer;
  late bool _isVisible;

  @override
  initState() {
    super.initState();
    _resetQueryTimer();
    _isVisible = true;
    _loading = ValueNotifier(false);
  }

  @override
  dispose() {
    if (_queryTimer.isActive) {
      _queryTimer.cancel();
    }

    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(state) {
    // Stop the timer if the app is backgrounded or otherwise
    // This behaves differently depending on device and may not be called.
    if (AppLifecycleState.resumed != state) {
      _queryTimer.cancel();
      return;
    }

    if (!mounted) {
      return;
    }

    // Trigger a rebuild to force the DB to query again.
    // Restart the timer.
    setState(() {
      if (_queryTimer.isActive) {
        _queryTimer.cancel();
      }
      _resetQueryTimer();
    });
  }

  @override
  void didPopNext() {
    _isVisible = true;
  }

  @override
  void didPushNext() {
    _isVisible = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (null == ModalRoute.of(context)) {
      return;
    }
    widget.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void _resetQueryTimer() {
    _queryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (!_isVisible) {
        return;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final apple = Platform.isMacOS || Platform.isIOS;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (pop, result) {},
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
                            await Navigator.push(
                                    this.context,
                                    (apple)
                                        ? CupertinoPageRoute(
                                            builder: (context) => LoginScreen(
                                                controller: widget.controller))
                                        : MaterialPageRoute(
                                            builder: (context) => LoginScreen(
                                                controller: widget.controller)))
                                .then((_) {
                              if (!mounted) {
                                return;
                              }
                              _loading.value = false;
                            });
                          }),
                  if (loggedIn)
                    ListTile(
                        title: const Text('Sign Out'),
                        onTap: () async {
                          // Pop the drawer
                          Navigator.pop(context);

                          // Sign out.
                          _loading.value = true;
                          await widget.controller.signOut().then((_) {
                            _loading.value = false;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) {
                                return;
                              }
                              const successBar = SnackBar(
                                  content: Text('Successfully logged out.'));
                              ScaffoldMessenger.of(this.context)
                                ..clearSnackBars()
                                ..showSnackBar(successBar);
                            });
                          }, onError: (e, s) {
                            _loading.value = false;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) {
                                return;
                              }
                              const errorBar = SnackBar(
                                  content: Text('Sorry! Error signing out.'));

                              ScaffoldMessenger.of(this.context)
                                ..clearSnackBars()
                                ..showSnackBar(errorBar);
                            });
                          });
                        }),
                ]),
              ),
              body: Stack(children: [
                ReportViewerMap(
                    controller: widget.controller,
                    handleError: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) {
                          return;
                        }
                        final errorBar = SnackBar(
                          content: const Text('Error retrieving new reports.'),
                          action: SnackBarAction(
                              label: 'Retry?',
                              onPressed: () => setState(() {})),
                        );
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(errorBar);
                      });
                    }),
                const FloatingMenuButton(),
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
