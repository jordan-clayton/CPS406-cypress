import 'package:latlong2/latlong.dart';

abstract interface class LocationService {
  LatLng getLocation();
  void close();
}
