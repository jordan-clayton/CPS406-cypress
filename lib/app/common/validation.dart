import 'constants.dart' as constants;
import 'utils.dart';

bool insideToronto(num lat, num long) =>
    calculateSphericalDistance(
        lat1: lat,
        long1: long,
        lat2: constants.torontoLat,
        long2: constants.torontoLong) <=
    constants.torontoRadius;

bool validEmail(String email) {
  const pattern = r'^[^@]+@[^@]+\.[^@]+$';
  return _applyRegExp(email, pattern);
}

bool validPhone(String phone) {
  // Phone pattern:
  // Group 1: (optional) Country code
  // Group 2: Area code (with optional parens)
  // Optional dash/space
  // Exchange code
  // Optional dash/space
  // Subscriber number
  const pattern =
      r'^(\+?\d{1,3}[\s.-]?)?(\(?\d{1,4}\)?[\s.-]?)?(\d{1,4}[\s.-]?)*\d{1,4}$';
  return _applyRegExp(phone, pattern);
}

bool _applyRegExp(String string, String pattern) {
  final exp = RegExp(pattern);
  return exp.hasMatch(string);
}
