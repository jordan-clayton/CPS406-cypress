// Basic design: A scaffold with the map with an initial location passed in as
// an argument to the constructor (if not the user's location, then the centre of toronto)
// The main widget should be a scaffold with a button that can pop the context to return back
// There scaffold body should be the map at the location

// On a tap, set a marker, and make two floating action buttons appear: one to cancel the marker,
// one to accept the location set.

// On accept, pop the context and return the longitude/latitude from the map
// The caller that pushes this route should await the results

import 'package:cypress/app/common/constants.dart';
import 'package:flutter/material.dart';

// TODO: this will have to be stateful, refactor accordingly
class LocationPicker extends StatelessWidget {
  LocationPicker({super.key});

  final ValueNotifier<bool> _selected = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: integrate flutter_map
      body: const Center(child: Text('map here pls')),
      floatingActionButton: ValueListenableBuilder(
          valueListenable: _selected,
          builder: (context, selected, child) {
            if (!selected) {
              // Return a null object instead of a button
              return const SizedBox.shrink();
            }
            return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              FloatingActionButton(
                  onPressed: () {
                    _selected.value = false;
                  },
                  child: const Icon(Icons.cancel_outlined)),
              const SizedBox(width: 8),
              FloatingActionButton(
                  onPressed: () {
                    _selected.value = false;
                    // TODO: integrate map API, pull the coordinates from the selected marker.
                    Navigator.pop(context, (torontoLat, torontoLong));
                  },
                  child: const Icon(Icons.check_rounded)),
            ]);
          }),
    );
  }
}
