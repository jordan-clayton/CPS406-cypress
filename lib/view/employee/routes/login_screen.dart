import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:os_detect/os_detect.dart' as os_detect;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/internal/internal_controller.dart';
import '../../../app/common/validation.dart';
import '../../common/widgets/adaptive_appbar.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final InternalController controller;

  @override
  State<LoginScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginScreen> {
  // For preventing grandma-clicks
  late final ValueNotifier<bool> _loading;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late String _email;
  late String _password;
  String? _errorEmail;
  String? _errorPassword;

  @override
  initState() {
    super.initState();
    // Init controllers
    _loading = ValueNotifier(false);
    _initTextControllers();
  }

  @override
  dispose() {
    // Dispose controllers.
    _emailController.removeListener(_listenEmail);
    _emailController.dispose();
    _passwordController.removeListener(_listenPassword);
    _passwordController.dispose();
    super.dispose();
  }

  void _initTextControllers() {
    // Email
    _email = '';
    _emailController = TextEditingController();
    _emailController.addListener(_listenEmail);
    // Password
    _password = '';
    _passwordController = TextEditingController();
    _passwordController.addListener(_listenPassword);
  }

  void _listenEmail() {
    SemanticsService.announce(
      'Email: ${_emailController.text}',
      TextDirection.ltr,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _email = _emailController.text;
      _errorEmail = null;
    });
  }

  void _listenPassword() {
    SemanticsService.announce(
        'Password: ${_passwordController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _password = _passwordController.text;
      _errorPassword = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apple = os_detect.isMacOS || os_detect.isIOS;
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Employee Log In'),
      body: ListView(children: [
        if (apple && null != _errorEmail)
          Text(_errorEmail!,
              style: const TextStyle(
                  color: CupertinoColors.systemRed, fontSize: 12)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: (apple)
              ? CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'Email',
                )
              : TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Email',
                      errorText: _errorEmail),
                ),
        ),
        if (apple && null != _errorPassword)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorPassword!,
                style: const TextStyle(
                    color: CupertinoColors.systemRed, fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: (apple)
              ? CupertinoTextField(
                  controller: _passwordController,
                  obscureText: true,
                  placeholder: 'Password')
              : TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Password',
                      errorText: _errorPassword),
                ),
        ),

        // Button to sign in
        ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loggingIn, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                    icon: (loggingIn)
                        ? const CircularProgressIndicator.adaptive()
                        : const Icon(null),
                    onPressed: (loggingIn ||
                            _email.isEmpty ||
                            _password.isEmpty)
                        ? null
                        : () async {
                            // Validate email
                            if (!validEmail(_email)) {
                              if (mounted) {
                                setState(() {
                                  _errorEmail = 'Invalid email format';
                                });
                              }
                              return;
                            }

                            // Validate password
                            if (_password.length < 6) {
                              if (mounted) {
                                setState(() {
                                  _errorPassword =
                                      'Password must be more than 6 characters.';
                                });
                              }
                            }

                            _loading.value = true;
                            // Log in
                            await widget.controller
                                .logIn(email: _email, password: _password)
                                .then((loggedIn) async {
                              if (loggedIn) {
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.pop(context);
                                // Give the navigator some time to pop the context.
                                await Future.delayed(
                                        const Duration(milliseconds: 200))
                                    .then((_) {
                                  if (!mounted) {
                                    return;
                                  }
                                  _loading.value = false;
                                });
                              } else {
                                // Either an invalid email or password.
                                _loading.value = false;
                                setState(() {
                                  _errorEmail = 'Failed to find account';
                                  _errorPassword = 'Invalid email or password';
                                });
                              }
                            }, onError: (e, s) {
                              _loading.value = false;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) {
                                  return;
                                }
                                if (e is AuthException &&
                                    e.code == 'invalid_credentials') {
                                  if (mounted) {
                                    setState(() {
                                      _errorEmail = 'Failed to find account';
                                      _errorPassword =
                                          'Invalid email or password';
                                    });
                                  }
                                }
                                const errorBar = SnackBar(
                                    content: Text('Error logging in.'));
                                ScaffoldMessenger.of(this.context)
                                  ..clearSnackBars()
                                  ..showSnackBar(errorBar);
                              });
                            });
                          },
                    label: const Text('Sign in')),
              );
            }),
        // Button to sign up
        
      ]),
    );
  }
}
