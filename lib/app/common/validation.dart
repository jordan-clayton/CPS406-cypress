// TODO: validation functions
import '../../models/report.dart';
import 'constants.dart' as constants;
import 'utils.dart';

bool insideToronto(Report r1) =>
    calculateSphericalDistance(
        lat1: r1.latitude,
        long1: r1.longitude,
        lat2: constants.torontoLat,
        long2: constants.torontoLong) <=
    constants.torontoRadius;

// TODO: regex
bool validEmail(String email) =>
    throw UnimplementedError("email validation not implemented");
bool validPhone(String phone) =>
    throw UnimplementedError("phone validation not implemented");
