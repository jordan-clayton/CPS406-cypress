import 'package:flutter/material.dart';
import 'app/client/main_screen.dart';
import 'app/client/report_page.dart'; 

/// Let this be the 'client application for end users'
/// Define a separate main for the internal 'employee application'
// TODO: implement
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cypress App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
      routes: {
        '/report': (context) => ReportPage(),
      }, 
    );
  }
}
