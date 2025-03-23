import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'constants.dart' as constants;

// This will need to be replicated server side if we implement sorting by distance
// This returns the spherical distance between two points in kilometers
// Uses Haversine: https://www.movable-type.co.uk/scripts/latlong.html
num calculateSphericalDistance(
    {required num lat1,
    required num long1,
    required num lat2,
    required num long2}) {
  final phi1 = radians(lat1.toDouble());
  final phi2 = radians(lat2.toDouble());
  final deltaPhi = radians(lat1.toDouble() - lat2.toDouble());
  final deltaLambda = radians(long2.toDouble() - long2.toDouble());

  final a = pow(sin(deltaPhi / 2), 2) +
      cos(phi1) * cos(phi2) * pow(sin(deltaLambda / 2), 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return constants.haversine * c;
}

num calculateSquaredDistance(Vector2 v1, Vector2 v2) =>
    v1.distanceToSquared(v2);
