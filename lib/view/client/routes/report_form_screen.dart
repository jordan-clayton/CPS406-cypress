// TODO:
// This should be a basic form entry field
import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';

// We might be able to get away with stateless widgets.
// The ValueListenablebuilder is itself stateful.
class ReportFormScreen extends StatefulWidget {
  // TODO: determine whether this can actually be const.
  const ReportFormScreen({super.key, required this.controller});
  final ClientController controller;
  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final ValueNotifier<bool> _submitPressed = ValueNotifier(false);
  // TODO: text controllers and drop-downs and the like.
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
