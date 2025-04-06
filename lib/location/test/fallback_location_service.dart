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
}
