import 'package:cypress/models/report.dart';
import 'package:cypress/view/employee/routes/report_detail_screen.dart';
import 'package:flutter/material.dart';

import '../../../app/internal/internal_controller.dart';

class ReportList extends StatelessWidget {
  final List<Report> reports;

  final InternalController controller;
  final void Function()? onSuccessfulUpdate;
  const ReportList(
      {super.key,
      required this.reports,
      required this.controller,
      this.onSuccessfulUpdate});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const Text('No reports found');
    }

    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: ListView.builder(
          controller: ScrollController(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(
                    'Report #${report.id.toString()}, Category: ${report.category.toString()}'),
                subtitle: Text(report.description),
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReportDetailScreen(
                            report: report, controller: controller)),
                  );

                  if (null == updated) {
                    return;
                  }

                  if (!updated) {
                    return;
                  }
                  // On a successful update, run the closure.
                  onSuccessfulUpdate?.call();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
