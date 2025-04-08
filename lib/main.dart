import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'view/client/routes/main_screen.dart';
import 'view/client/routes/report_page.dart';

/// Let this be the 'client application for end users'
/// Define a separate main for the internal 'employee application'
// TODO: implement
Future<void> main() async{
  await Supabase.initialize(
    url: 'https://fndttgvspjfukajgwjpo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZuZHR0Z3ZzcGpmdWthamd3anBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwNzE3NDUsImV4cCI6MjA1OTY0Nzc0NX0.A2G57hgH-qooC0ICQfw2uc7gXz9caEB4eqnd_ydQCmo',
  );
  
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

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
