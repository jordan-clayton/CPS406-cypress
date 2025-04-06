import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/common/constants.dart' as constants;
import '../../common/utils/map_utils.dart';

class LocationPickerMap extends StatelessWidget {
  const LocationPickerMap(
      {super.key,
      this.initialLocation,
      this.selectedLocation,
      this.initialZoom,
      this.onLocationPicked,
      this.onPositionChanged});

  final LatLng? selectedLocation;
  final LatLng? initialLocation;
  final double? initialZoom;
  final void Function(LatLng? newLoc)? onLocationPicked;
  final void Function(LatLng newCen, double zoom)? onPositionChanged;

  @override
  Widget build(context) {
    final loc = initialLocation ??
        const LatLng(constants.torontoLat, constants.torontoLong);
    return FlutterMap(
        options: MapOptions(
            initialCenter: loc,
            initialZoom: initialZoom ?? 13.0,
            onTap: (_, p) => onLocationPicked?.call(p),
            onPositionChanged: (c, _) =>
                onPositionChanged?.call(c.center, c.zoom),
            keepAlive: true),
        children: [
          mapLayer,
          if (null != selectedLocation)
            MarkerLayer(markers: [
              Marker(
                point: selectedLocation!,
                width: 30,
                height: 30,
                // TODO: if time, implement dragging.
                child: GestureDetector(
                  onTap: () => onLocationPicked?.call(null),
                  child: const Icon(Icons.location_pin,
                      color: Colors.black, size: 30),
                ),
              )
            ])
        ]);
  }
}
