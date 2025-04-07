import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../app/client/client_controller.dart';
import '../../../app/common/validation.dart';
import '../../common/widgets/adaptive_appbar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.controller});

  final ClientController controller;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late ValueNotifier<bool> _loading;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  late String _email;
  late String _password;
  String? _phoneError;
  String? _emailError;
  String? _username;
  String? _phone;

  @override
  initState() {
    super.initState();
    _loading = ValueNotifier(false);
    _initControllers();
  }

  @override
  dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initControllers() {
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
  }

  void _disposeControllers() {
    _emailController.removeListener(_listenEmail);
    _emailController.dispose();

    _usernameController.removeListener(_listenUsername);
    _usernameController.dispose();

    _passwordController.removeListener(_listenPassword);
    _passwordController.dispose();

    _phoneController.removeListener(_listenPhone);
    _phoneController.dispose();
  }

  void _listenEmail() {
    setState(() {
      _email = _emailController.text;
      _emailError = null;
    });
    SemanticsService.announce('Email: $_email', TextDirection.ltr);
  }

  void _listenUsername() {
    setState(() {
      _username = _usernameController.text;
    });
    SemanticsService.announce('Username: $_username', TextDirection.ltr);
  }

  void _listenPhone() {
    setState(() {
      _phone = _phoneController.text;
      _phoneError = null;
    });
    SemanticsService.announce('Phone: $_phone', TextDirection.ltr);
  }

  void _listenPassword() {
    setState(() {
      _password = _passwordController.text;
    });
    SemanticsService.announce('Password: $_password', TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    bool apple = Platform.isMacOS || Platform.isIOS;
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Sign Up'),
      body: ListView(children: _buildAdaptiveTextFields(apple: apple)),
    );
  }

  List<Widget> _buildAdaptiveTextFields({required bool apple}) {
    // Common
    const optionalHeader = ListTile(
      title: Text('Optional:'),
    );
    const requiredHeader = ListTile(title: Text('Required:'));

    // Buttons.
    final signUpButton = ValueListenableBuilder(
        valueListenable: _loading,
        builder: (context, loading, child) {
          return FilledButton.icon(
              icon: (loading)
                  ? const CircularProgressIndicator.adaptive()
                  : const Icon(null),
              onPressed: (loading || _email.isEmpty || _password.isEmpty)
                  ? null
                  : () async {
                      // Validate
                      if (!validEmail(_email)) {
                        setState(() {
                          _emailError = 'Invalid email format';
                        });
                        return;
                      }
                      if (null != _phone && !validPhone(_phone!)) {
                        setState(() {
                          _phoneError = 'Invalid phone number';
                        });
                        return;
                      }
                      // Assume username is correct and push the sign-up
                      _loading.value = true;
                      await widget.controller
                          .signUp(
                              email: _email,
                              password: _password,
                              username: _username,
                              phone: _phone)
                          .then((signedUp) async {
                        if (signedUp) {
                          if (!context.mounted) {
                            return;
                          }

                          Navigator.pop(context);
                          await Future.delayed(
                                  const Duration(milliseconds: 200))
                              .then((_) {
                            if (mounted) {
                              _loading.value = false;
                            }
                          });
                        } else {
                          _loading.value = false;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              const errorBar = SnackBar(
                                  content: Text('Sign up unsuccessful'));
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(errorBar);
                            }
                          });
                        }
                      }, onError: (e, s) {
                        _loading.value = false;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            const errorBar =
                                SnackBar(content: Text('Error signing up'));
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(errorBar);
                          }
                        });
                      });
                    },
              label: const Text('Sign up'));
        });

    // Cupertino
    if (apple) {
      return [
        // Optional fields
        optionalHeader,
        // Username
        CupertinoTextField(
            controller: _usernameController, placeholder: 'Username'),
        // Phone
        CupertinoTextField(
          controller: _phoneController,
          placeholder: 'Phone',
          keyboardType: TextInputType.phone,
        ),
        if (null != _phoneError)
          Text(_phoneError!,
              style: const TextStyle(
                  color: CupertinoColors.systemRed, fontSize: 12)),
        // Required fields
        requiredHeader,
        CupertinoTextField(
          controller: _emailController,
          placeholder: 'Email',
        ),
        if (null != _emailError)
          Text(_emailError!,
              style: const TextStyle(
                  color: CupertinoColors.systemRed, fontSize: 12)),
        CupertinoTextField(
          controller: _passwordController,
          obscureText: true,
          placeholder: 'Password',
        ),
        signUpButton
      ];
    }
    // Material
    return [
      optionalHeader,
      TextField(
        controller: _usernameController,
        decoration: const InputDecoration(
          labelText: 'Username',
        ),
      ),
      TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone',
            errorText: _phoneError,
          )),
      requiredHeader,
      TextField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          errorText: _emailError,
        ),
      ),
      TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
          )),
      signUpButton
    ];
  }
}
