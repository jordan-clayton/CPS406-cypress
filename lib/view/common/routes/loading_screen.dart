import 'package:flutter/material.dart';

import '../widgets/adaptive_appbar.dart';

/// A basic loading screen to indicate to the user that some sort of work is
/// going on before the next view.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: adaptiveAppBar(title: 'Cypress: Now Loading'),
        body: const Center(child: CircularProgressIndicator.adaptive()));
  }
}
