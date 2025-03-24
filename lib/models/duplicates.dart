import 'package:equatable/equatable.dart';

enum DuplicateSeverity implements Comparable<DuplicateSeverity> {
  unlikely,
  possible,
  suspected,
  confirmed;

  factory DuplicateSeverity.fromString(String ds) => switch (ds.toLowerCase()) {
        'unlikely' => unlikely,
        'possible' => possible,
        'suspected' => suspected,
        'confirmed' => confirmed,
        _ => throw FormatException("Invalid duplicate severity format: $ds")
      };

  @override
  int compareTo(DuplicateSeverity other) => index.compareTo(other.index);
}

// Ignore the warning here, the primary key is immutable and what's used for
// hashing.
class DuplicateReport extends Equatable implements Comparable<DuplicateReport> {
  final int reportID;
  final int matchID;
  DuplicateSeverity severity;

  DuplicateReport(
      {required this.reportID, required this.matchID, required this.severity});

  factory DuplicateReport.fromEntity({required Map<String, dynamic> entity}) =>
      DuplicateReport(
          reportID: entity['report_id'] as int,
          matchID: entity['match_id'] as int,
          severity: DuplicateSeverity.fromString(entity['severity']));

  Map<String, dynamic> toEntity() => {
        'report_id': reportID,
        'match_id': matchID,
        'DuplicateSeverity': severity.name
      };

  @override
  List<Object> get props => [reportID, matchID];

  @override
  int compareTo(DuplicateReport other) =>
      reportID.compareTo(other.reportID) +
      matchID.compareTo(other.matchID) +
      severity.compareTo(other.severity);
}
