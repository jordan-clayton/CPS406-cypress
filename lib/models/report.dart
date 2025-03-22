// TODO: define equality; implement comparable
enum ProblemCategory {
  crime,
  fire,
  water,
  infrastructure;

  factory ProblemCategory.fromString(String pc) => switch (pc.toLowerCase()) {
        'crime' => ProblemCategory.crime,
        'fire' => ProblemCategory.fire,
        'water' => ProblemCategory.water,
        'infrastructure' => ProblemCategory.infrastructure,
        _ => throw FormatException('Invalid problem category format: $pc')
      };
}

enum ProgressStatus {
  opened,
  inProgress,
  closed;

  factory ProgressStatus.fromString(String ps) => switch (ps.toLowerCase()) {
        'opened' => ProgressStatus.opened,
        'in-progress' => ProgressStatus.inProgress,
        'closed' => ProgressStatus.closed,
        _ => throw FormatException('Invalid progress format: $ps')
      };
}

// TODO: define equality; implement comparable
// TODO: define toEntity method
class Report {
  num id;
  ProblemCategory category;
  num latitude;
  num longitude;
  String description;
  bool verified;
  ProgressStatus progress;

  Report(
      {required this.id,
      required this.category,
      required this.latitude,
      required this.longitude,
      this.description = '',
      this.verified = false,
      this.progress = ProgressStatus.opened});

  Report.fromEntity(Map<String, dynamic> entity)
      : id = entity['id'] as num,
        category = ProblemCategory.fromString(entity['category']),
        latitude = entity['latitude'] as num,
        longitude = entity['longitude'] as num,
        description = entity['description'],
        verified = entity['verified'] as bool,
        progress = ProgressStatus.fromString(entity['progress']);
}
