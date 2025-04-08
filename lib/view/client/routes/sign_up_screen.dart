import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../../app/client/client_controller.dart';
import '../../../app/common/validation.dart';
import '../../common/widgets/adaptive_appbar.dart';
import 'login_screen.dart';

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
    _email = '';
    _emailController.addListener(_listenEmail);
    _usernameController = TextEditingController();
    _usernameController.addListener(_listenUsername);
    _phoneController = TextEditingController();
    _phoneController.addListener(_listenPhone);
    _passwordController = TextEditingController();
    _passwordController.addListener(_listenPassword);
    _password = '';
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
    final apple = os_detect.isMacOS || os_detect.isIOS;
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Sign Up'),
      body: ListView(children: _buildAdaptiveTextFields(apple: apple)),
    );
  }

  List<Widget> _buildAdaptiveTextFields({required bool apple}) {
    // Common
    const optionalHeader = Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [Text('Optional:')],
      ),
    );
    const requiredHeader = Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [Text('Required:')]),
    );

    // Buttons.
    final signUpButton = ValueListenableBuilder(
        valueListenable: _loading,
        builder: (context, loading, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.icon(
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
                            // Re-route the user to the login screen
                            Navigator.pushReplacement(
                                this.context,
                                (apple)
                                    ? CupertinoPageRoute(
                                        builder: (context) => LoginScreen(
                                            controller: widget.controller))
                                    : MaterialPageRoute(
                                        builder: (context) => LoginScreen(
                                            controller: widget.controller)));
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

                              const errorBar = SnackBar(
                                  content: Text('Sign up unsuccessful'));
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
                label: const Text('Sign up')),
          );
        });

    // Cupertino
    if (apple) {
      return [
        // Optional fields
        optionalHeader,
        // Username
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
              controller: _usernameController, placeholder: 'Username'),
        ),
        // Phone
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
            controller: _phoneController,
            placeholder: 'Phone',
            keyboardType: TextInputType.phone,
          ),
        ),
        if (null != _errorPhone)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorPhone!,
                style: const TextStyle(
                    color: CupertinoColors.systemRed, fontSize: 12)),
          ),
        // Required fields
        requiredHeader,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
            controller: _emailController,
            placeholder: 'Email',
          ),
        ),
        if (null != _errorEmail)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorEmail!,
                style: const TextStyle(
                    color: CupertinoColors.systemRed, fontSize: 12)),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
            controller: _passwordController,
            obscureText: true,
            placeholder: 'Password',
          ),
        ),
        if (null != _errorPassword)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorPassword!,
                style: const TextStyle(
                    color: CupertinoColors.systemRed, fontSize: 12)),
          ),
        signUpButton
      ];
    }
    // Material
    return [
      optionalHeader,
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Username',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Phone',
              errorText: _errorPhone,
            )),
      ),
      requiredHeader,
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _emailController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Email',
            errorText: _errorEmail,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Password',
              errorText: _errorPassword,
            )),
      ),
      signUpButton
    ];
  }
}
