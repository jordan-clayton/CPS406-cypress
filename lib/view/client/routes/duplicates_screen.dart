import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';
import '../../../models/report.dart';
import '../widgets/map_report_picker.dart';

class DuplicatesScreen extends StatefulWidget {
  const DuplicatesScreen({super.key, required this.controller});

  final ClientController controller;

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> {
  late Future<List<Report>> _loadReports;
  int? _selectedReport;

  @override
  void initState() {
    super.initState();
    _loadReports = _getReports();
  }

  // Using a microtask here to bump the priority of the scheduler and run this
  // as soon as it appears in synchronous code.
  Future<List<Report>> _getReports() => Future.microtask(() async {
        return await widget.controller.getCurrentReports();
      });

  void onLocationPicked(int id) {
    if (mounted) {
      setState(() {
        _selectedReport = id;
      });
    }
  }

  void onDismiss() {
    if (mounted) {
      setState(() {
        _selectedReport = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder(
            future: _loadReports,
            builder: (context, snapshot) {
              var done = snapshot.connectionState == ConnectionState.done;
              if (snapshot.hasError ||
                  (done && (snapshot.data?.isEmpty ?? true))) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final errorBar = SnackBar(
                    content: const Text('Failed to retrieve reports'),
                    action: SnackBarAction(
                        label: 'Retry?',
                        onPressed: () {
                          setState(() {
                            _loadReports = _getReports();
                          });
                        }),
                  );

                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(errorBar);
                });
              }
              final List<Report> reports =
                  (done) ? snapshot.data ?? const [] : const [];
              return Stack(children: [
                ReportPickerMap(
                    reports: reports,
                    selectedID: _selectedReport,
                    initialLocation: widget.controller.clientLocation,
                    onLocationPicked: onLocationPicked,
                    onDismiss: onDismiss),
                if (!done)
                  const Center(child: CircularProgressIndicator.adaptive())
              ]);
            }),
        floatingActionButton: FloatingActionButton(
            child: (null != _selectedReport)
                ? const Icon(Icons.check_rounded)
                : const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.pop(context, _selectedReport);
            }),
      );
}
