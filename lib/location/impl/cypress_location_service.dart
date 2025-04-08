import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/common/constants.dart' as constants;
import '../interface/location_service.dart';

class CypressLocationService implements LocationService {
  Position _lastLocation;
  late StreamSubscription<Position> _positionStream;

  CypressLocationService()
      : _lastLocation = Position(
            longitude: constants.torontoLong,
            latitude: constants.torontoLat,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
            isMocked: true) {
    _init();
  }

  Future<void> _init() async {
    // NOTE: Geolocator doesn't support linux :<
    if (Platform.isLinux || Platform.isFuchsia) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If there is no access to location permissions, just accept the fallback toronto position
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return;
    }

    // Otherwise, set up the streamsubscription.
    return _initSubscription();
  }

  void _initSubscription() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (null != position) {
        _lastLocation = position;
      }
    });
  }

  @override
  void close() {
    _positionStream.cancel();
  }

  @override
  LatLng getLocation() {
    return LatLng(_lastLocation.latitude, _lastLocation.longitude);
  }
}
