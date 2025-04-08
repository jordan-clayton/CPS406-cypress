import 'dart:math';

import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:intl/intl.dart';

import '../../models/report.dart';
import 'constants.dart' as constants;
import 'utils.dart';

/// Collection of testable functions to integrate with a Controller class
/// that's concerned with whether reports are duplicates or invalid

// Possible approach: scoring with thresholds for likelihood, eg. Unlikely, Possible, Suspected, Likely
num duplicateReportScore({required Report r1, required Report r2}) {
  num score = 0.0;
  score += (reportCloseTo(r1: r1, r2: r2)) ? constants.closeToScore : 0.0;
  score += (r1.category == r2.category) ? constants.categoryScore : 0.0;
  score += constants.frequencyWeight *
      reportWordSimilarity(desc1: r1.description, desc2: r2.description);
  return max(score, 100);
}

bool reportCloseTo({required Report r1, required Report r2}) =>
    calculateSphericalDistance(
        lat1: r1.latitude,
        long1: r1.longitude,
        lat2: r2.latitude,
        long2: r2.longitude) <=
    constants.locationDistanceThreshold;

// Does fuzzy string matching to determine how similar descriptions are
// Takes the weightedRatio, which returns the "best" (ie. highest of the
// fuzz-matching algorithms, eg. Levenstein, Token set).
// The closer the strings match, the higher the score.
// NOTE: this does not account for semantics and relies on duplicate reports
// containing -some- degree of lexical redundancy.
double reportWordSimilarity({required String desc1, required String desc2}) {
  return weightedRatio(desc1, desc2) / 100;
}

String generateReportMessage({required Report r}) {
  return 'REPORT UPDATE: \n'
      'Progress: ${toBeginningOfSentenceCase(r.progress.name)}\n'
      'Category: ${toBeginningOfSentenceCase(r.category.name)}\n'
      'Description: ${r.description}\n';
}
