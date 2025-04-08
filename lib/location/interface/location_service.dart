import 'package:latlong2/latlong.dart';

abstract interface class LocationService {
  LatLng getLocation();
  bool get hasPermission;
  void close();
  void addLocationListener(
      {required String owner,
      required void Function(bool) onPermissionChanged});
  void removeLocationListener({required String owner});
}
