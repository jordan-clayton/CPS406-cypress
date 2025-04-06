import 'package:flutter/material.dart';

import '../widgets/adaptive_appbar.dart';

class ErrorScreen extends StatelessWidget {
  ErrorScreen(
      {super.key, required this.errorMessage, required this.recoveryFunction});

  final String errorMessage;
  final ValueNotifier<bool> _retryPressed = ValueNotifier(false);

  /// Closure for recovering from an error; could be as simple as popping a context.
  final void Function() recoveryFunction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Cypress: Error'),
      body: Center(child: Text(errorMessage)),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: _retryPressed,
        builder: (context, pressed, child) {
          return FloatingActionButton.large(
              onPressed: (pressed)
                  ? null
                  : () async {
                      _retryPressed.value = true;
                      recoveryFunction();
                      // To give the animation enough time and prevent grandma-clicks
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (context.mounted) {
                        _retryPressed.value = false;
                      }
                    },
              child: (pressed)
                  ? const CircularProgressIndicator.adaptive()
                  : const Icon(Icons.refresh_rounded));
        },
      ),
    );
  }
}
