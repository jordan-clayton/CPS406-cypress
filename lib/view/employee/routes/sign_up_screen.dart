import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../../app/client/employee_controller.dart';
import '../../../app/common/validation.dart';
import '../../common/widgets/adaptive_appbar.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.controller});

  final EmployeeController controller;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late ValueNotifier<bool> _loading;
  late TextEditingController _idController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _passwordController;

  late String _id;
  late String _password;
  String? _errorPhone;
  String? _errorID;
  String? _errorPassword;
  String? _firstName;
  String? _lastName;

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
    _idController = TextEditingController();
    _id = '';
    _idController.addListener(_listenID);
    _firstNameController = TextEditingController();
    _firstNameController.addListener(_listenFirstName);
    _lastNameController = TextEditingController();
    _lastNameController.addListener(_listenLastName);
    _passwordController = TextEditingController();
    _passwordController.addListener(_listenPassword);
    _password = '';
  }

  void _disposeControllers() {
    _idController.removeListener(_listenID);
    _idController.dispose();

    _firstNameController.removeListener(_listenFirstName);
    _firstNameController.dispose();
  
    _lastNameController.removeListener(_listenLastName);
    _lastNameController.dispose();

    _passwordController.removeListener(_listenPassword);
    _passwordController.dispose();

    
  }

  void _listenID() {
    SemanticsService.announce(
        'ID: ${_idController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _id = _idController.text;
      _errorID = null;
    });
  }

  void _listenFirstName() {
    SemanticsService.announce(
        'First Name: ${_firstNameController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _firstName = _firstNameController.text;
    });
  }

  void _listenLastName() {
    SemanticsService.announce(
        'Phone: ${_lastNameController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _lastName = _lastNameController.text;
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
                onPressed: (loading || _id.isEmpty || _password.isEmpty)
                    ? null
                    : () async {
                        // Validate
                        // if (!validEmail(_id)) {
                        //   if (mounted) {
                        //     setState(() {
                        //       _errorID = 'Invalid email format';
                        //     });
                        //   }
                        //   return;
                        // }
                        // if (null != _phone && !validPhone(_phone!)) {
                        //   if (mounted) {
                        //     setState(() {
                        //       _errorPhone = 'Invalid phone number';
                        //     });
                        //   }
                        //   return;
                        // }

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
                                employeeID: _id,
                                firstName: _firstName,
                                lastName: _lastName,
                                password: _password)
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
                label: const Text('Sign up blallarhg')),
          );
        });

    // Cupertino
    if (apple) {
      return [
        // Optional fields
        // optionalHeader,
        // Username
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
              controller: _firstNameController, placeholder: 'First Name'),
        ),
        // Phone
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CupertinoTextField(
            controller: _lastNameController,
            placeholder: 'Last Name',
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
            controller: _idController,
            placeholder: 'Employee ID',
          ),
        ),
        if (null != _errorID)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_errorID!,
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
      // optionalHeader,
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'First Name',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
            controller: _lastNameController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'Last Name',
              errorText: _errorPhone,
            )),
      ),
      requiredHeader,
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _idController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Employee ID',
            errorText: _errorID,
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
