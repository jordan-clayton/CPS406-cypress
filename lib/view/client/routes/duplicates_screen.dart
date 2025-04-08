import 'package:flutter/material.dart';

import '../../../app/client/client_controller.dart';
import '../../../models/report.dart';
import '../../common/widgets/adaptive_appbar.dart';
import '../widgets/map_report_picker.dart';

class DuplicatesPickerScreen extends StatefulWidget {
  const DuplicatesPickerScreen(
      {super.key, required this.controller, required this.suspectedDup});

  final ClientController controller;
  final Report suspectedDup;

  @override
  State<DuplicatesPickerScreen> createState() => _DuplicatesPickerScreenState();
}

class _DuplicatesPickerScreenState extends State<DuplicatesPickerScreen> {
  late Future<List<Report>> _loadReports;
  int? _selectedReport;

  // For guarding against grandma clicks.
  late ValueNotifier<bool> _loading;

  @override
  void initState() {
    super.initState();
    _loadReports = _getReports();
    _loading = ValueNotifier(false);
  }

  // Using a microtask here to bump the priority of the scheduler and run this
  // as soon as it appears in synchronous code.
  Future<List<Report>> _getReports() => Future.microtask(() async {
        return await widget.controller.getCurrentReports();
      });

  void onLocationPicked(int id) {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedReport = id;
    });
  }

  void onDismiss() {
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedReport = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: adaptiveAppBar(title: 'Select Duplicate Report'),
        body: FutureBuilder(
            future: _loadReports,
            builder: (context, snapshot) {
              final done = snapshot.connectionState == ConnectionState.done;
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
              // Future TODO: query that filters out the single record.
              final List<Report> reports =
                  (done) ? snapshot.data ?? const [] : const [];
              return Stack(children: [
                ReportPickerMap(
                    reports:
                        // Filter out the suspected report.
                        reports.where((r) => r != widget.suspectedDup).toList(),
                    selectedID: _selectedReport,
                    initialLocation: widget.controller.clientLocation,
                    onLocationPicked: onLocationPicked,
                    onDismiss: onDismiss),
                if (!done)
                  const Center(child: CircularProgressIndicator.adaptive())
              ]);
            }),
        floatingActionButton: ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loading, child) {
              return FloatingActionButton(
                  onPressed: (loading)
                      ? null
                      : () async {
                          _loading.value = true;
                          Navigator.pop(this.context, _selectedReport);
                          await Future.delayed(
                                  const Duration(milliseconds: 200))
                              .then((_) {
                            if (!mounted) {
                              return;
                            }
                            _loading.value = false;
                          });
                        },
                  child: (loading)
                      ? const CircularProgressIndicator.adaptive()
                      : (null != _selectedReport)
                          ? const Icon(Icons.check_rounded)
                          : const Icon(Icons.cancel_outlined));
            }),
      );
}
