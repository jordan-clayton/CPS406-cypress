import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../common/widgets/floating_menu_button.dart';
import '../widgets/map_location_picker.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  LatLng? _mapCenter;
  double? _cameraZoom;
  // For preventing grandma-clicks
  late ValueNotifier<bool> _loading;

  @override
  initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _mapCenter = widget.initialLocation;
    _loading = ValueNotifier(false);
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
        ValueListenableBuilder(
            valueListenable: _loading,
            builder: (context, loading, child) {
              return FloatingMenuButton(
                button: IconButton(
                    icon: (loading)
                        ? const CircularProgressIndicator.adaptive()
                        : const Icon(Icons.arrow_back_rounded),
                    onPressed: (loading)
                        ? null
                        : () async {
                            _loading.value = true;
                            Navigator.pop(this.context, null);
                            await Future.delayed(
                                    const Duration(milliseconds: 200))
                                .then((_) {
                              if (!mounted) {
                                return;
                              }

                              _loading.value = false;
                            });
                          }),
              );
            }),
      ]),
      floatingActionButton: (null != _selectedLocation)
          ? ValueListenableBuilder(
              valueListenable: _loading,
              builder: (context, loading, child) {
                return FloatingActionButton(
                    onPressed: (loading)
                        ? null
                        : () async {
                            _loading.value = true;
                            Navigator.pop(this.context, _selectedLocation);
                            await Future.delayed(
                                    const Duration(milliseconds: 200))
                                .then((_) {
                              if (!mounted) {
                                return;
                              }
                              _loading.value = false;
                            });
                          },
                    child: (loading)
                        ? const CircularProgressIndicator.adaptive()
                        : const Icon(Icons.check_rounded));
              })
          : null,
    );
  }
}
