import 'package:latlong2/latlong.dart';

import '../../app/common/constants.dart' as constants;
import '../interface/location_service.dart';

class FallbackLocationService implements LocationService {
  @override
  LatLng getLocation() {
    return const LatLng(constants.torontoLat, constants.torontoLong);
  }

  @override
  void close() {}

  @override
  bool get hasPermission => false;

  // These are NOPs; there's no location to listen to.
  @override
  void addLocationListener(
      {required String owner,
      required void Function(bool p1) onPermissionChanged}) {}

  @override
  void removeLocationListener({required String owner}) {}
}
