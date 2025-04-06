import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../common/widgets/floating_menu_button.dart';
import '../widgets/map_location_picker.dart';

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _selectedLocation;
  LatLng? _mapCenter;
  double? _cameraZoom;

  @override
  initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _mapCenter = widget.initialLocation;
  }

  void onLocationPicked(newLoc) => setState(() {
        _selectedLocation = newLoc;
      });

  void onPositionChanged(newCenter, newZoom) => setState(() {
        _mapCenter = newCenter;
        _cameraZoom = newZoom;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        LocationPickerMap(
          selectedLocation: _selectedLocation,
          // Passing the mapCenter down to the map to preserve the map's positioning.
          initialLocation: _mapCenter,
          initialZoom: _cameraZoom,
          onLocationPicked: onLocationPicked,
          onPositionChanged: onPositionChanged,
        ),
        FloatingMenuButton(
          button: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              }),
        ),
      ]),
      floatingActionButton: (null != _selectedLocation)
          ? FloatingActionButton(
              child: const Icon(Icons.check_rounded),
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              })
          : null,
    );
  }
}
