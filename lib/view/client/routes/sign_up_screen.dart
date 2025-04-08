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
  String? _errorPhone;
  String? _errorEmail;
  String? _errorPassword;
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
    SemanticsService.announce(
        'Email: ${_emailController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _email = _emailController.text;
      _errorEmail = null;
    });
  }

  void _listenUsername() {
    SemanticsService.announce(
        'Username: ${_usernameController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _username = _usernameController.text;
    });
  }

  void _listenPhone() {
    SemanticsService.announce(
        'Phone: ${_phoneController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _phone = _phoneController.text;
      _errorPhone = null;
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
    final apple = Platform.isMacOS || Platform.isIOS;
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
                        if (mounted) {
                          setState(() {
                            _errorEmail = 'Invalid email format';
                          });
                        }
                        return;
                      }
                      if (null != _phone && !validPhone(_phone!)) {
                        if (mounted) {
                          setState(() {
                            _errorPhone = 'Invalid phone number';
                          });
                        }
                        return;
                      }

                      if (_password.length < 6) {
                        if (mounted) {
                          setState(() {
                            _errorPassword =
                                'Password length must be at least 6 character.';
                          });
                        }
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
                          if (!mounted) {
                            return;
                          }

                          Navigator.pop(this.context);
                          await Future.delayed(
                                  const Duration(milliseconds: 200))
                              .then((_) {
                            if (!mounted) {
                              return;
                            }
                            _loading.value = false;
                          });
                        } else {
                          _loading.value = false;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) {
                              return;
                            }

                            const errorBar =
                                SnackBar(content: Text('Sign up unsuccessful'));
                            ScaffoldMessenger.of(this.context)
                              ..clearSnackBars()
                              ..showSnackBar(errorBar);
                          });
                        }
                      }, onError: (e, s) {
                        _loading.value = false;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }

                          const errorBar =
                              SnackBar(content: Text('Error signing up'));
                          ScaffoldMessenger.of(this.context)
                            ..clearSnackBars()
                            ..showSnackBar(errorBar);
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
        if (null != _errorPhone)
          Text(_errorPhone!,
              style: const TextStyle(
                  color: CupertinoColors.systemRed, fontSize: 12)),
        // Required fields
        requiredHeader,
        CupertinoTextField(
          controller: _emailController,
          placeholder: 'Email',
        ),
        if (null != _errorEmail)
          Text(_errorEmail!,
              style: const TextStyle(
                  color: CupertinoColors.systemRed, fontSize: 12)),
        CupertinoTextField(
          controller: _passwordController,
          obscureText: true,
          placeholder: 'Password',
        ),
        if (null != _errorPassword)
          Text(_errorPassword!,
              style: const TextStyle(
                  color: CupertinoColors.systemRed, fontSize: 12)),
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
            errorText: _errorPhone,
          )),
      requiredHeader,
      TextField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          errorText: _errorEmail,
        ),
      ),
      TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: _errorPassword,
          )),
      signUpButton
    ];
  }
}
