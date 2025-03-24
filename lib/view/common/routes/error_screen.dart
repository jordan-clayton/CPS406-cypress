import 'package:flutter/material.dart';

import '../widgets/adaptive_appbar.dart';

class ErrorScreen extends StatelessWidget {
  ErrorScreen({super.key, required this.errorMessage});

  final String errorMessage;
  final ValueNotifier<bool> _retryPressed = ValueNotifier(false);

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
                      Navigator.pop(context);
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
