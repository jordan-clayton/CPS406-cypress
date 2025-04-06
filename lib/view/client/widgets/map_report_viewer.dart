import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/client/client_controller.dart';
import '../../common/utils/map_utils.dart';
import '../routes/report_detail_screen.dart';

class ReportViewerMap extends StatefulWidget {
  const ReportViewerMap(
      {super.key, required this.controller, this.handleError});

  final ClientController controller;
  final void Function()? handleError;

  @override
  State<ReportViewerMap> createState() => _ReportViewerMapState();
}

class _ReportViewerMapState extends State<ReportViewerMap> {
  @override
  Widget build(context) => FutureBuilder(
      future: widget.controller.getCurrentReports(),
      builder: (context, snapshot) {
        List<Widget> children = [mapLayer];
        // If an error handler has been provided, call it on an error.
        if (snapshot.hasError) {
          widget.handleError?.call();
        }
        // Fill the children/marker layer.
        if (snapshot.connectionState == ConnectionState.done) {
          var markers = snapshot.data
                  ?.map((r) => Marker(
                        point: LatLng(
                            r.latitude.toDouble(), r.longitude.toDouble()),
                        width: 30,
                        height: 30,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ReportDetailScreen(
                                      report: r,
                                      controller: widget.controller))),
                          child: const Icon(Icons.location_pin,
                              size: 30, color: Colors.black),
                        ),
                      ))
                  .toList(growable: false) ??
              [];
          children.add(MarkerLayer(markers: markers));
        }
        return FlutterMap(
          options: MapOptions(
            initialCenter: widget.controller.clientLocation,
          ),
          children: children,
        );
      });
}
