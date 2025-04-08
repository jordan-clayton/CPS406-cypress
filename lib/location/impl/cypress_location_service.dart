import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

import '../../app/common/constants.dart' as constants;
import '../interface/location_service.dart';

class CypressLocationService implements LocationService {
  Position _lastLocation;
  late StreamSubscription<Position> _positionStream;
  StreamSubscription<ServiceStatus>? _permissionStream;
  Timer? _webPermissionPollingTimer;
  late final ValueNotifier<bool> _hasLocationServices;
  late final Map<String, void Function()> _locationListeners;

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
            isMocked: true),
        _hasLocationServices = ValueNotifier(false),
        _locationListeners = {} {
    _init();
  }

  Future<void> _init() async {
    // NOTE: Geolocator doesn't support linux :<
    if (os_detect.isLinux || os_detect.isFuchsia) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // If there is no access to location permissions, just accept the fallback toronto position
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      log('Denied or unable to determine');
      return;
    }

    // Otherwise, grab the location and set up the streamsubscription.
    log('Setting up location and stream.');
    await _trySetLocation();
    _initSubscription();
  }

  Future<void> _trySetLocation() async {
    const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(milliseconds: 500));
    try {
      if (kDebugMode) {
        log('Toronto default location: $_lastLocation');
      }
      _lastLocation = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
      log('Location should be set');
      _hasLocationServices.value = true;
      if (kDebugMode) {
        log('Newly set location: $_lastLocation');
      }
    } catch (e, s) {
      log(e.toString(), stackTrace: s);
    }
  }

  void _resetLocation() {
    // There's no need to reset the location if it's already reset.
    // Return early to prevent extra memory allocations.
    if (_hasLocationServices.value = false) {
      return;
    }
    // Change the location to just return the centre of toronto if/when location
    // services get turned off.
    _hasLocationServices.value = false;
    _lastLocation = Position(
      latitude: constants.torontoLat,
      longitude: constants.torontoLong,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: true,
    );
  }

  // Note: There is an open issue with geolocator's location stream.
  // It will sometimes just... stop or not work.
  // See: https://github.com/Baseflow/flutter-geolocator/issues/1391
  void _initSubscription() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position? position) {
              log('Position stream tryGet location');
              if (null != position) {
                _lastLocation = position;
                _hasLocationServices.value = true;
              }
              log('position from location stream returning null');
            },
            onDone: () {
              log('Locations stream closed');
            },
            cancelOnError: false,
            onError: (_) {
              log('Disabled service, reset location');
              _resetLocation();
            });

    // getServiceStatus isn't available for web.
    // Use the polling timer
    if (kIsWeb) {
      // The polling might need to be shorter to feel responsive.
      // It doesn't take too long to await the permission check.
      _webPermissionPollingTimer =
          Timer.periodic(const Duration(milliseconds: 500), (_) async {
        final permission = await Geolocator.checkPermission();
        if (LocationPermission.always == permission ||
            LocationPermission.whileInUse == permission) {
          await _trySetLocation();
        } else {
          _resetLocation();
        }
      });
    }
    // Otherwise, the application should have location services provided by the OS
    else {
      _permissionStream =
          Geolocator.getServiceStatusStream().listen((status) async {
        if (status == ServiceStatus.enabled) {
          // Update location and notify listeners
          log('Re-enabled service, try to get location');
          await _trySetLocation();
        } else {
          // Reset location and notify listeners
          log('Disabled service, reset location');
          _resetLocation();
        }
      });
    }
  }

  @override
  void close() {
    _positionStream.cancel();
    _permissionStream?.cancel();
    _webPermissionPollingTimer?.cancel();
  }

  @override
  LatLng getLocation() {
    return LatLng(_lastLocation.latitude, _lastLocation.longitude);
  }

  @override
  bool get hasPermission => _hasLocationServices.value;

  @override
  void addLocationListener(
      {required String owner,
      required void Function(bool) onPermissionChanged}) {
    // Remove any old void functions to be collected
    _locationListeners.remove(owner);
    _locationListeners[owner] =
        () => onPermissionChanged(_hasLocationServices.value);
    _hasLocationServices.addListener(_locationListeners[owner]!);
  }

  @override
  void removeLocationListener({required String owner}) {
    final callback = _locationListeners.remove(owner);
    if (null == callback) {
      log('Null location callback on remove.');
      return;
    }
    log('Removing location listener for: $owner');
    _hasLocationServices.removeListener(callback);
  }
}
