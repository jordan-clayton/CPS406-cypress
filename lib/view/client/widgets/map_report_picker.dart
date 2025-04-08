import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/common/constants.dart' as constants;
import '../../../models/report.dart';
import '../../common/utils/map_utils.dart';

class ReportPickerMap extends StatelessWidget {
  const ReportPickerMap(
      {super.key,
      required this.reports,
      this.selectedID,
      this.initialLocation,
      this.onLocationPicked,
      this.onDismiss});

  final LatLng? initialLocation;
  final int? selectedID;
  final List<Report> reports;
  final void Function(int id)? onLocationPicked;
  final void Function()? onDismiss;

  @override
  Widget build(context) {
    var markers = reports
        .map((r) => Marker(
              point: LatLng(r.latitude.toDouble(), r.longitude.toDouble()),
              width: 30,
              height: 30,
              child: GestureDetector(
                onTap: () async {
                  final picked = await showModalBottomSheet(
                    context: context,
                    builder: (context) => ListView(shrinkWrap: true, children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child: Text('Report: ${r.id}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium)),
                      ),
                      ListTile(
                        title: Text(
                            toBeginningOfSentenceCase(r.category.toString())),
                        subtitle: const Text('Category'),
                      ),
                      ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Description'),
                          subtitle: Text(r.description)),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 16.0),
                        child: FilledButton(
                            child: const Text('Confirm'),
                            onPressed: () {
                              Navigator.pop(context, true);
                            }),
                      )
                    ]),
                  );

                  if (null == picked || !picked) {
                    return;
                  }

                  onLocationPicked?.call(r.id);
                },
                child: (null != selectedID && selectedID == r.id)
                    ? const Icon(Icons.location_pin,
                        size: 30, color: Colors.blue)
                    : const Icon(Icons.location_pin,
                        size: 30, color: Colors.black),
              ),
            ))
        .toList(growable: false);
    return FlutterMap(
        options: MapOptions(
            initialCenter: initialLocation ??
                const LatLng(constants.torontoLat, constants.torontoLong),
            initialZoom: 15,
            onTap: (_, p) => onDismiss?.call(),
            keepAlive: true),
        children: [mapLayer, MarkerLayer(markers: markers)]);
  }
}
