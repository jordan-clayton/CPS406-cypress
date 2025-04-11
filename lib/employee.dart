import 'package:flutter/material.dart';

import 'app/common/loading.dart';
import 'view/employee/employee_application.dart';

/// Let this be the 'internal application for employees'
void main() {
  runApp(EmployeeApplication(
      initializeController: initializeInternalControllerWithSupabase()));
}
