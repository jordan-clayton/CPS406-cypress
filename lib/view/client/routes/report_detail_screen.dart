import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/client/client_controller.dart';
import '../../../models/flagged.dart';
import '../../../models/report.dart';
import '../../common/widgets/adaptive_appbar.dart';
import 'duplicates_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen(
      {super.key, required this.report, required this.controller});

  final Report report;
  final ClientController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: adaptiveAppBar(title: 'Report: ${report.id}'),
      body: ListView(children: [
        // Verified
        (report.verified)
            ? ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Verified'),
                subtitle: const Text('Verification status'),
                tileColor: Theme.of(context).colorScheme.primary)
            : ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: const Text('Unverified'),
                subtitle: const Text('Verification status'),
                tileColor: Theme.of(context).colorScheme.error),
        const Divider(),
        // Progress status
        switch (report.progress) {
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
            title: Text(toBeginningOfSentenceCase(report.category.name)),
            subtitle: const Text('Problem type')),
        const Divider(),
        // Description
        Card(
          child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Description'),
              subtitle: Text(report.description)),
        ),
        const Divider(),
        // Flag report
        TextButton(
            child: const Text('Flag report'),
            onPressed: () async {
              if (controller.loggedIn.value) {
                var flaggedReason = await showConfirmationDialog(
                  context: context,
                  title: 'Reason',
                  actions: FlaggedReason.values
                      .map((r) => AlertDialogAction(
                            label: toBeginningOfSentenceCase(r.toString()),
                            key: r,
                          ))
                      .toList(),
                );
                if (null == flaggedReason) {
                  return;
                }

                // Flag the report
                await controller
                    .flagReport(flaggedID: report.id, reason: flaggedReason)
                    .then((_) async {
                  if (!context.mounted) {
                    return;
                  }
                  await showOkAlertDialog(
                      context: context,
                      title: 'Report flagged',
                      message: 'Thanks for your help!');

                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                }, onError: (e, s) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) {
                      return;
                    }
                    const errorBar =
                        SnackBar(content: Text('Sorry, an error occurred'));
                    ScaffoldMessenger.of(context)
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
                    message: 'You must be signed in to flag reports');
              }
            }),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
        // Mark duplicate
        TextButton(
            child: const Text('Tag duplicate'),
            onPressed: () async {
              if (controller.loggedIn.value) {
                var apple = Platform.isMacOS || Platform.isIOS;
                // Push to the duplicates picker.
                var matchID = await Navigator.push(
                    context,
                    (apple)
                        ? CupertinoPageRoute(
                            builder: (context) =>
                                DuplicatesScreen(controller: controller))
                        : MaterialPageRoute(
                            builder: (context) =>
                                DuplicatesScreen(controller: controller)));

                if (null == matchID) {
                  return;
                }

                // Flag the duplicate.
                await controller
                    .reportDuplicate(
                        suspectedDupID: report.id, matchID: matchID)
                    .then((_) async {
                  if (!context.mounted) {
                    return;
                  }
                  await showOkAlertDialog(
                      context: context,
                      title: 'Duplicate flagged',
                      message: 'Thanks for your help!');

                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pop(context);
                }, onError: (e, s) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) {
                      return;
                    }
                    const errorBar =
                        SnackBar(content: Text('Sorry, an error occurred'));
                    ScaffoldMessenger.of(context)
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
                    message: 'You must be signed in to flag reports');
              }
            })
      ]),
    );
  }
}
