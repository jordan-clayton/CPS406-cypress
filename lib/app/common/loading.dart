import 'package:supabase_flutter/supabase_flutter.dart';

import '../../db/impl/postgrest_db_service.dart';
import '../../db/impl/supabase_client.dart';
import '../../location/impl/cypress_location_service.dart';
import '../../login/impl/supabase_login.dart';
import '../client/client_controller.dart';
import '../common/constants.dart' as constants;

// NOTE: write other implementation initializers as appropriate
/// Initialization function to start the app using supabase implementation
Future<ClientController> initializeControllerWithSupabase() async {
  // Initialize clients
  SupabaseClient? supabase;

  // There is no field I can check and .initialize throws when called twice.
  // This has to be in a try block :<
  try {
    await Supabase.initialize(
        url: constants.supabaseURL, anonKey: constants.supabaseAnonKey);
    supabase = Supabase.instance.client;
  } catch (e) {
    supabase = SupabaseClient(constants.supabaseURL, constants.supabaseAnonKey);
  }

  final dbClient = SupabaseImpl.withClient(client: supabase);
  final loginService = SupabaseLoginService.withClient(client: supabase);
  final dbService = PostgrestDatabaseService(client: dbClient);
  final locationService = CypressLocationService();
  final controller = ClientController(
      databaseService: dbService,
      loginService: loginService,
      locationService: locationService,
      loggedIn: loginService.hasSession);

  // If the user has a profile with the app, try grabbing the data
  // Nothing will happen if the user is not logged in.
  controller.tryRestoreUserSession();

  return controller;
}
