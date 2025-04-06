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
  const pattern = r'^(\+\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$';
  return _applyRegExp(phone, pattern);
}

bool _applyRegExp(String string, String pattern) {
  final exp = RegExp(pattern);
  return exp.hasMatch(string);
}
