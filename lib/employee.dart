import 'package:cypress/app/client/employee_controller.dart';
import 'package:flutter/material.dart';

import 'app/common/loading.dart';
import 'view/employee/employee_application.dart';

/// Let this be the 'client application for end users'
/// Define a separate main for the internal 'employee application'
/// 
/// 
/// definitely needs to be checked
void main() {
  runApp(EmployeeApplication(
    initializeController: initializeControllerWithSupabase() as Future<EmployeeController>,
  ));
}
