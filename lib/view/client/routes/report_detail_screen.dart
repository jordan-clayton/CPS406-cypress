import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../../app/client/client_controller.dart';
import '../../../models/flagged.dart';
import '../../../models/report.dart';
import '../../common/widgets/adaptive_appbar.dart';
import 'duplicates_screen.dart';
import 'subscription_info_picker.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen(
      {super.key, required this.report, required this.controller});

  final Report report;
  final ClientController controller;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

// TODO: subscriptions.
class _ReportDetailScreenState extends State<ReportDetailScreen>
    with WidgetsBindingObserver {
  // Guard against grandma clicks.
  late ValueNotifier<bool> _loading;

  @override
  initState() {
    super.initState();
    _loading = ValueNotifier(false);
  }

  @override
  Widget build(BuildContext context) {
    final apple = os_detect.isMacOS || os_detect.isIOS;
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Report: ${widget.report.id}'),
      body: ListView(children: [
        // Verified
        (widget.report.verified)
            ? ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Verified'),
                subtitle: const Text('Verification status'),
                tileColor: Theme.of(context).colorScheme.inversePrimary)
            : ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: const Text('Unverified'),
                subtitle: const Text('Verification status'),
                tileColor: Theme.of(context).colorScheme.error),
        const Divider(),
        // Subscribe button
        ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loading, child) {
              return Tooltip(
                message: (widget.report.verified)
                    ? 'Subscribe to progress updates.'
                    : 'Reports must be verified by the City before subscribing.',
                child: ListTile(
                    onTap: (loading || !widget.report.verified)
                        ? null
                        : () async {
                            _loading.value = true;
                            final subscriptionDTO = await Navigator.push(
                                context,
                                (apple)
                                    ? CupertinoPageRoute(
                                        builder: (context) =>
                                            SubscriptionInfoPickerScreen(
                                                reportID: widget.report.id,
                                                user: widget.controller.user))
                                    : MaterialPageRoute(
                                        builder: (context) =>
                                            SubscriptionInfoPickerScreen(
                                                reportID: widget.report.id,
                                                user: widget.controller.user)));

                            // If the user pops the context without submitting information
                            // Assume they don't want to subscribe and repaint the screen.
                            if (null == subscriptionDTO) {
                              if (mounted) {
                                _loading.value = false;
                              }
                              return;
                            }

                            // Otherwise, subscribe the user.
                            await widget.controller
                                .subscribe(info: subscriptionDTO)
                                .then((_) {
                              _loading.value = false;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) {
                                  return;
                                }
                                const successBar =
                                    SnackBar(content: Text('Subscribed!'));
                                ScaffoldMessenger.of(this.context)
                                  ..clearSnackBars()
                                  ..showSnackBar(successBar);
                              });
                            }, onError: (e, s) {
                              _loading.value = false;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) {
                                  return;
                                }
                                const errorBar = SnackBar(
                                    content:
                                        Text('Sorry! Something went wrong.'));
                                ScaffoldMessenger.of(this.context)
                                  ..clearSnackBars()
                                  ..showSnackBar(errorBar);
                              });
                            });
                          },
                    title: const Text("Subscribe to updates"),
                    leading: const Icon(Icons.notification_add_outlined)),
              );
            }),
        const Divider(),
        // Progress status
        switch (widget.report.progress) {
          ProgressStatus.opened => const ListTile(
              leading: Icon(Icons.start_rounded),
              title: Text('Opened'),
              subtitle: Text('Progress status'),
            ),
          ProgressStatus.inProgress => const ListTile(
              leading: Icon(Icons.track_changes_rounded),
              title: Text('In Progress'),
              subtitle: Text('Progress status')),
          ProgressStatus.closed => const ListTile(
              leading: Icon(Icons.done_all_rounded),
              title: Text('Closed'),
              subtitle: Text('Progress status')),
        },
        const Divider(),
        // Category
        ListTile(
            leading: const Icon(Icons.category),
            title: Text(toBeginningOfSentenceCase(widget.report.category.name)),
            subtitle: const Text('Problem type')),
        const Divider(),
        // Description
        Card(
          child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Description'),
              subtitle: Text(widget.report.description)),
        ),
        const Divider(),
        // Flag report
        ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loading, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton(
                    onPressed: (loading)
                        ? null
                        : () async {
                            if (widget.controller.loggedIn.value) {
                              var flaggedReason = await showConfirmationDialog(
                                context: context,
                                title: 'Reason',
                                actions: FlaggedReason.values
                                    .map((r) => AlertDialogAction(
                                          label: toBeginningOfSentenceCase(
                                              r.toString()),
                                          key: r,
                                        ))
                                    .toList(),
                              );
                              if (null == flaggedReason) {
                                _loading.value = false;
                                return;
                              }

                              // Flag the report
                              _loading.value = true;
                              await widget.controller
                                  .flagReport(
                                      flaggedID: widget.report.id,
                                      reason: flaggedReason)
                                  .then((_) async {
                                if (!mounted) {
                                  return;
                                }
                                await showOkAlertDialog(
                                    context: this.context,
                                    title: 'Report flagged',
                                    message: 'Thanks for your help!');

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
                                _loading.value = false;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) {
                                    return;
                                  }
                                  const errorBar = SnackBar(
                                      content:
                                          Text('Sorry, an error occurred'));
                                  ScaffoldMessenger.of(this.context)
                                    ..clearSnackBars()
                                    ..showSnackBar(errorBar);
                                });
                              });
                            } else {
                              // Show an alert dialog that pops.
                              // Future feature: push to sign-in screen
                              await showOkAlertDialog(
                                  context: context,
                                  title: 'Authentication required',
                                  message:
                                      'You must be signed in to flag reports');
                            }
                          },
                    child: const Text('Flag report')),
              );
            }),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
        // Mark duplicate
        ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loading, child) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                child: FilledButton.tonal(
                    onPressed: (loading)
                        ? null
                        : () async {
                            if (widget.controller.loggedIn.value) {
                              // Push to the duplicates picker.
                              _loading.value = true;
                              final matchID = await Navigator.push(
                                  context,
                                  (apple)
                                      ? CupertinoPageRoute(
                                          builder: (context) =>
                                              DuplicatesPickerScreen(
                                                  controller: widget.controller,
                                                  suspectedDup: widget.report))
                                      : MaterialPageRoute(
                                          builder: (context) =>
                                              DuplicatesPickerScreen(
                                                controller: widget.controller,
                                                suspectedDup: widget.report,
                                              )));

                              if (null == matchID) {
                                _loading.value = false;
                                return;
                              }

                              // Flag the duplicate.
                              await widget.controller
                                  .reportDuplicate(
                                      suspectedDupID: widget.report.id,
                                      matchID: matchID)
                                  .then((_) async {
                                if (!mounted) {
                                  return;
                                }
                                await showOkAlertDialog(
                                    context: this.context,
                                    title: 'Duplicate flagged',
                                    message: 'Thanks for your help!');

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
                                _loading.value = false;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) {
                                    return;
                                  }
                                  const errorBar = SnackBar(
                                      content:
                                          Text('Sorry, an error occurred'));
                                  ScaffoldMessenger.of(this.context)
                                    ..clearSnackBars()
                                    ..showSnackBar(errorBar);
                                });
                              });
                            } else {
                              // Show an alert dialog that pops.
                              // Future feature: push to sign-in screen
                              await showOkAlertDialog(
                                  context: context,
                                  title: 'Authentication required',
                                  message:
                                      'You must be signed in to flag reports');
                            }
                          },
                    child: const Text('Tag duplicate')),
              );
            })
      ]),
    );
  }
}
