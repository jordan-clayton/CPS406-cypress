import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart' as intl;
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../../app/common/validation.dart';
import '../../../models/subscription.dart';
import '../../../models/user.dart';
import '../../common/widgets/adaptive_appbar.dart';

class SubscriptionInfoPickerScreen extends StatefulWidget {
  const SubscriptionInfoPickerScreen(
      {super.key, required this.reportID, this.user});

  final int reportID;
  final UserView? user;

  @override
  State<SubscriptionInfoPickerScreen> createState() =>
      _SubscriptionInfoPickerScreen();
}

class _SubscriptionInfoPickerScreen
    extends State<SubscriptionInfoPickerScreen> {
  NotificationMethod? _notificationMethod;
  String? _contactInfo;

  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _errorEmail;
  String? _errorPhone;

  late ValueNotifier<bool> _loading;

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
    // Populate the text field with the previously stored info if it exists.
    _emailController = TextEditingController(text: widget.user?.email);
    _emailController.addListener(_listenEmail);
    _phoneController = TextEditingController(text: widget.user?.phone);
    _phoneController.addListener(_listenPhone);
  }

  void _disposeControllers() {
    _emailController.removeListener(_listenEmail);
    _emailController.dispose();
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
      _errorEmail = null;
      _contactInfo = _emailController.text;
    });
  }

  void _listenPhone() {
    SemanticsService.announce(
        'Phone: ${_phoneController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _errorEmail = null;
      _contactInfo = _phoneController.text;
    });
  }

  bool _validateContact() {
    switch (_notificationMethod) {
      case NotificationMethod.sms:
        if (!validPhone(_contactInfo!)) {
          if (mounted) {
            setState(() {
              _errorPhone = 'Invalid phone format.';
            });
          }
          return false;
        }
      case NotificationMethod.email:
        if (!validEmail(_contactInfo!)) {
          if (mounted) {
            setState(() {
              _errorEmail = 'Invalid email format.';
            });
          }
          return false;
        }
      case NotificationMethod.push:
        return false;
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        (null != _notificationMethod && (_contactInfo ?? '').isNotEmpty);
    final apple = os_detect.isMacOS || os_detect.isIOS;
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Subscription'),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownMenu(
            // This will force the dropdown to fill all available space of the parent
            expandedInsets: EdgeInsets.zero,
            label: const Text('Notification method'),
            initialSelection: _notificationMethod,
            onSelected: (newMethod) {
              if (!mounted) {
                return;
              }

              setState(() {
                _notificationMethod = newMethod;
                // Keep the contact info field coherent.
                _contactInfo = switch (_notificationMethod) {
                  NotificationMethod.sms => _phoneController.text,
                  NotificationMethod.email => _emailController.text,
                  NotificationMethod.push => null,
                  _ => null,
                };
              });
            },
            dropdownMenuEntries: NotificationMethod.values
                .map((e) => DropdownMenuEntry(
                    value: e, label: intl.toBeginningOfSentenceCase(e.name)))
                .toList(growable: false),
          ),
        ),

        // This will output nothing (sizedbox.shrink) if there are no errors.
        if (apple) _appleErrorField(),
        // Adaptive textfield for inputting the contact info.
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _inputField(apple: apple),
        ),
        const Divider(),
        // Submit button.
        ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loading, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                  onPressed: (!canSubmit || loading)
                      ? null
                      : () async {
                          if (!_validateContact()) {
                            return;
                          }
                          _loading.value = true;
                          // Return the subscription DTO.
                          Navigator.pop(
                              context,
                              SubscriptionDTO(
                                  reportID: widget.reportID,
                                  notificationMethod: _notificationMethod!,
                                  contact: _contactInfo!));
                          await Future.delayed(
                                  const Duration(milliseconds: 200))
                              .then((_) {
                            if (mounted) {
                              _loading.value = false;
                            }
                          });
                        },
                  child: const Text('Submit'),
                ),
              );
            }),
      ]),
    );
  }

  Widget _inputField({bool apple = false}) => switch (_notificationMethod) {
        null => const SizedBox.shrink(),
        NotificationMethod.sms => (apple)
            ? CupertinoTextField(
                controller: _phoneController,
                placeholder: 'Phone',
                keyboardType: TextInputType.phone,
              )
            : TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Phone',
                    errorText: _errorPhone)),
        NotificationMethod.email => (apple)
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
        // Future TODO: Handle push notifications.
        NotificationMethod.push => const Text('Not implemented'),
      };

  Widget _appleErrorField() => Padding(
        padding: const EdgeInsets.all(8.0),
        child: switch (_notificationMethod) {
          NotificationMethod.sms => (null != _errorPhone)
              ? Text(_errorPhone!,
                  style: const TextStyle(
                      color: CupertinoColors.systemRed, fontSize: 12))
              : const SizedBox.shrink(),
          NotificationMethod.email => (null != _errorEmail)
              ? Text(_errorEmail!,
                  style: const TextStyle(
                      color: CupertinoColors.systemRed, fontSize: 12))
              : const SizedBox.shrink(),
          _ => const SizedBox.shrink(),
        },
      );
}
