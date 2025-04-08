import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../../app/client/client_controller.dart';
import '../../../app/common/constants.dart' as constants;
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
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _markers = [];
    _mapController = MapController();
    widget.controller.addLocationListener(
        owner: 'report_viewer',
        onPermissionChanged: _onLocationPermissionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeLocationListener(owner: 'report_viewer');
    super.dispose();
  }

  void _onLocationPermissionChanged(bool permission) {
    log('LocationPermissionChanged');
    if (!mounted) {
      log('Not mounted');
      return;
    }
    setState(() {
      if (permission) {
        log('Should be moving location');
        log('Expect moving to ${widget.controller.clientLocation}');
        _mapController.move(
            widget.controller.clientLocation, _mapController.camera.zoom);
      } else {
        _mapController.move(
            const LatLng(constants.torontoLat, constants.torontoLong),
            _mapController.camera.zoom);
      }
    });
  }

  @override
  Widget build(context) => FutureBuilder(
      future: widget.controller.getCurrentReports(),
      builder: (context, snapshot) {
        // For "Apple-y" page transitions.
        final apple = os_detect.isMacOS || os_detect.isIOS;

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
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.controller.clientLocation,
            initialZoom: 15,
          ),
          children: children,
        );
      });
}
