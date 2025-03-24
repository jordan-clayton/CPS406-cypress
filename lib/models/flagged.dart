import 'package:equatable/equatable.dart';

enum FlaggedReason implements Comparable<FlaggedReason> {
  nonEmergency,
  ambiguous,
  falseReport,
  malicious;

  factory FlaggedReason.fromString(String fr) => switch (fr.toLowerCase()) {
        'non-emergency' => nonEmergency,
        'ambiguous' => ambiguous,
        'false-report' => falseReport,
        'malicious' => malicious,
        _ => throw FormatException("Invalid flag reason: $fr")
      };

  @override
  toString() => switch (this) {
        nonEmergency => 'non-emergency',
        ambiguous => 'ambiguous',
        falseReport => 'false-report',
        malicious => 'malicious'
      };

  @override
  int compareTo(FlaggedReason other) => index.compareTo(other.index);
}

class Flagged extends Equatable implements Comparable<Flagged> {
  final int reportID;
  final FlaggedReason reason;
  const Flagged({required this.reportID, required this.reason});

  factory Flagged.fromEntity({required Map<String, dynamic> entity}) => Flagged(
      reportID: entity['report_id'] as int,
      reason: FlaggedReason.fromString(entity['flagged_reason']));

  Map<String, dynamic> toEntity() =>
      {'report_id': reportID, 'flagged_reason': reason.toString()};

  @override
  List<Object?> get props => [reportID, reason];

  @override
  int compareTo(Flagged other) =>
      reportID.compareTo(other.reportID) + reason.compareTo(other.reason);
}
