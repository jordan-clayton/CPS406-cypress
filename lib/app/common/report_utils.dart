import 'package:cypress/app/common/utils.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import 'constants.dart' as constants;

/// Collection of testable functions to integrate with a Controller class
/// that's concerned with whether reports are duplicates or invalid

// Possible approach: scoring with thresholds for likelihood, eg. Unlikely, Possible, Suspected, Likely
num duplicateReportScore({required Report r1, required Report r2}) {
  num score = 0.0;
  score += (reportCloseTo(r1: r1, r2: r2)) ? constants.closeToScore : 0.0;
  score += (r1.category == r2.category) ? constants.categoryScore : 0.0;
  score += reportWordFrequency(r1: r1, r2: r2);
  return score;
}

bool reportCloseTo({required Report r1, required Report r2}) =>
    calculateSphericalDistance(
        lat1: r1.latitude,
        long1: r1.longitude,
        lat2: r2.latitude,
        long2: r2.longitude) <=
    constants.locationDistanceThreshold;

// NOTE: word-frequency might not be the smartest way to go about this
// NLP would be out of scope for the project, but would be the best way to
// solve this problem
double reportWordFrequency({required Report r1, required Report r2}) {
  // Proposed (naive) approach: Make two hashmaps to collect non-conjunctions/articles
  // Then take the difference of words that appear in each hashmap.
  throw UnimplementedError('TODO! Word frequency comparison');
}

String generateReportMessage({required Report r}) {
  return 'REPORT UPDATE: \n'
      'Progress: ${toBeginningOfSentenceCase(r.progress.name)}\n'
      'Category: ${toBeginningOfSentenceCase(r.category.name)}\n'
      'Description: ${r.description}\n';
}
