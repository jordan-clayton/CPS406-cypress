import 'dart:io';

import 'package:flutter/cupertino.dart';
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
  // To prevent flickering, cache the previous snapshot's report records.
  // This happens in the background; the repaint happens whenever there's new data.
  late List<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = [];
  }

  @override
  Widget build(context) => FutureBuilder(
      future: widget.controller.getCurrentReports(),
      builder: (context, snapshot) {
        // For "Apple-y" page transitions.
        final apple = Platform.isMacOS || Platform.isIOS;

        List<Widget> children = [mapLayer, mapAttribution];
        // If an error handler has been provided, call it on an error.
        if (snapshot.hasError) {
          widget.handleError?.call();
        }
        // Fill the children/marker layer.
        if (snapshot.connectionState == ConnectionState.done) {
          _markers = snapshot.data
                  ?.map((r) => Marker(
                        point: LatLng(
                            r.latitude.toDouble(), r.longitude.toDouble()),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              (apple)
                                  ? CupertinoPageRoute(
                                      builder: (context) => ReportDetailScreen(
                                          report: r,
                                          controller: widget.controller))
                                  : MaterialPageRoute(
                                      builder: (context) => ReportDetailScreen(
                                          report: r,
                                          controller: widget.controller))),
                          child: const Icon(Icons.location_pin,
                              size: 40, color: Colors.black),
                        ),
                      ))
                  .toList(growable: false) ??
              [];
        }
        // To reduce flickering on bg refresh, use the cached _markers.
        children.add(MarkerLayer(markers: _markers));
        return FlutterMap(
          options: MapOptions(
            initialCenter: widget.controller.clientLocation,
            initialZoom: 15,
          ),
          children: children,
        );
      });
}
