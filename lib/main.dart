import 'package:flutter/material.dart';

import 'app/common/loading.dart';
import 'view/client/client_application.dart';

/// Let this be the 'client application for end users'
/// Define a separate main for the internal 'employee application'
void main() {
  runApp(ClientApplication(
    initializeController: initializeControllerWithSupabase(),
  ));
}
