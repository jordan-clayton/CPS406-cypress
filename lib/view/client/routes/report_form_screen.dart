import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart' as intl;
import 'package:latlong2/latlong.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../../app/client/client_controller.dart';
import '../../../app/common/validation.dart';
import '../../../models/report.dart';
import '../../common/widgets/adaptive_appbar.dart';
import 'location_picker_screen.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, required this.controller});

  final ClientController controller;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final ValueNotifier<bool> _loading = ValueNotifier(false);
  late final TextEditingController _descriptionController;
  late String _description;
  late LatLng _location;
  ProblemCategory? _category;

  @override
  initState() {
    _location = widget.controller.clientLocation;
    _initControllers();
    super.initState();
  }

  @override
  dispose() {
    _descriptionController.removeListener(_descriptionListen);
    _descriptionController.dispose();
    super.dispose();
  }

  void _initControllers() {
    _descriptionController = TextEditingController();
    _description = '';
    _descriptionController.addListener(_descriptionListen);
  }

  void _descriptionListen() {
    SemanticsService.announce(
        'Description: ${_descriptionController.text}', TextDirection.ltr);
    if (!mounted) {
      return;
    }
    setState(() {
      _description = _descriptionController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apple = os_detect.isMacOS || os_detect.isIOS;
    final canSubmit = _description.isNotEmpty && null != _category;
    return ValueListenableBuilder(
        valueListenable: _loading,
        builder: (context, loading, child) {
          return Scaffold(
            appBar: adaptiveAppBar(title: 'New Report'),
            body: ListView(children: [
              // Category
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownMenu(
                  // This will expand the drop-down to fill all horizontal space.
                  expandedInsets: EdgeInsets.zero,
                  label: const Text('Category'),
                  initialSelection: _category,
                  onSelected: (ProblemCategory? newCat) {
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _category = newCat;
                    });
                  },
                  dropdownMenuEntries: ProblemCategory.values
                      .map((c) => DropdownMenuEntry(
                          value: c,
                          label: intl.toBeginningOfSentenceCase(c.name)))
                      .toList(growable: false),
                ),
              ),
              const Divider(),
              // Location
              ListTile(
                  leading: const Icon(Icons.location_history),
                  title: Text(
                      'Latitude: ${_location.latitude.toStringAsFixed(2)}, Longitude: ${_location.longitude.toStringAsFixed(2)}'),
                  subtitle: const Text('location'),
                  onTap: (loading)
                      ? null
                      : () async {
                          // Move to the location picker screen.
                          _loading.value = true;
                          final newLoc = await Navigator.push(
                              this.context,
                              (apple)
                                  ? CupertinoPageRoute(
                                      builder: (context) =>
                                          LocationPickerScreen(
                                              initialLocation: _location))
                                  : MaterialPageRoute(
                                      builder: (context) =>
                                          LocationPickerScreen(
                                              initialLocation: _location)));

                          _location = newLoc ?? _location;
                          if (!mounted) {
                            return;
                          }

                          _loading.value = false;
                        }),
              const Divider(),
              // Description
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                    controller: _descriptionController,
                    // TODO: decide on whether we want to fix the number of characters
                    // And how many characters that should be.
                    maxLength: 1000,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder())),
              ),
              const Divider(),
              // Submit
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                    onPressed: (!canSubmit || loading)
                        ? null
                        : () async {
                            // Validate location.
                            if (!insideToronto(
                                _location.latitude, _location.longitude)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) {
                                  return;
                                }

                                const errorBar = SnackBar(
                                    content:
                                        Text('Location not inside Toronto'));
                                ScaffoldMessenger.of(this.context)
                                  ..clearSnackBars()
                                  ..showSnackBar(errorBar);
                              });
                              return;
                            }
                            // Submit function.
                            _loading.value = true;
                            await widget.controller
                                .makeReport(
                                    newReport: Report(
                                        id: 0,
                                        category: _category!,
                                        latitude: _location.latitude,
                                        longitude: _location.longitude,
                                        description: _description))
                                .then((_) async {
                              if (!mounted) {
                                return;
                              }

                              await showOkAlertDialog(
                                  context: this.context,
                                  title: 'Report Submitted',
                                  message: 'Thank you for submitting a report. '
                                      'The City of Toronto will get to fixing this as soon as possible.');
                              if (!mounted) {
                                return;
                              }
                              Navigator.pop(this.context);
                              await Future.delayed(
                                      const Duration(milliseconds: 200))
                                  .then((_) {
                                if (!mounted) {
                                  return;
                                }

                                _loading.value = false;
                              });
                            }, onError: (e, s) {
                              if (!mounted) {
                                return;
                              }

                              _loading.value = false;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) {
                                  return;
                                }

                                const errorBar = SnackBar(
                                    content: Text(
                                        'Sorry! Error submitting report.'));
                                ScaffoldMessenger.of(this.context)
                                  ..clearSnackBars()
                                  ..showSnackBar(errorBar);
                              });
                            });
                          },
                    icon: (loading)
                        ? const CircularProgressIndicator.adaptive()
                        : const Icon(null),
                    label: const Text('Submit')),
              ),
            ]),
          );
        });
  }
}
