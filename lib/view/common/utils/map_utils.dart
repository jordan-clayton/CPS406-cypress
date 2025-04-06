import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// Basic tile layer, requires attribution as part of TOS.
TileLayer get mapLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileProvider: CancellableNetworkTileProvider(),
    );

// From flutter_map: https://github.com/fleaflet/flutter_map/blob/cdb3b230376d1452b03e90f2d49ad2c26979244d/example/lib/pages/home.dart
RichAttributionWidget get mapAttribution => RichAttributionWidget(
        popupInitialDisplayDuration: const Duration(seconds: 3),
        animationConfig: const ScaleRAWA(),
        attributions: [
          TextSourceAttribution('OpenStreetMap contributors',
              onTap: () async => launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright'),
                  )),
          const TextSourceAttribution(
            'This attribution is the same throughout this app except where otherwise specified.',
            prependCopyright: false,
          ),
        ]);
