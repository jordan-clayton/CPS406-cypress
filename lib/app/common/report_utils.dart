import 'package:cypress/app/common/utils.dart';

import '../../models/report.dart';
import 'constants.dart' as constants;

/// Collection of testable functions to integrate with a Controller class
/// that's concerned with whether reports are duplicates or invalid

// TODO: this should be handled differently.
// Possible approach: scoring with thresholds for likelihood, eg. Unlikely, Possible, Suspected, Likely
bool duplicateReport(Report r1, Report r2) =>
    r1.category == r2.category &&
    reportCloseTo(r1, r2) &&
    reportWordFrequency(r1, r2);

bool reportCloseTo(Report r1, Report r2) =>
    calculateSphericalDistance(
        lat1: r1.latitude,
        long1: r1.longitude,
        lat2: r2.latitude,
        long2: r2.longitude) <=
    constants.locationDistanceThreshold;

// NOTE: word-frequency might not be the smartest way to go about this
// NLP would be out of scope for the project, but would be the best way to
// solve this problem
bool reportWordFrequency(Report r1, Report r2) {
  // Proposed (naive) approach: Make two hashmaps to collect non-conjunctions/articles
  // Then take the difference of words that appear in each hashmap.
  throw UnimplementedError('TODO! Word frequency comparison');
}
