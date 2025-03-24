import 'package:supabase_flutter/supabase_flutter.dart';

import '../../db/impl/postgrest_db_service.dart';
import '../../db/impl/supabase_client.dart';
import '../../login/impl/supabase_login.dart';
import '../client/client_controller.dart';
import '../common/constants.dart' as constants;

// NOTE: write other implementation initializers as appropriate

/// Initialization function to start the app using supabase implementation
Future<ClientController> initializeControllerWithSupabase() async {
  // Initialize clients
  await Supabase.initialize(
      url: constants.supabaseURL, anonKey: constants.supabaseAnonKey);

  final supabase = Supabase.instance;
  final dbClient = SupabaseImpl.withClient(client: supabase.client);
  final loginService = SupabaseLoginService.withClient(client: supabase.client);
  final dbService = PostgrestDatabaseService(client: dbClient);
  final controller = ClientController(
      databaseService: dbService,
      loginService: loginService,
      loggedIn: loginService.hasSession);

  // If the user has a profile with the app, try grabbing the data
  // Nothing will happen if the user is not logged in.
  controller.tryRestoreUserSession();

  return controller;
}
