import 'package:equatable/equatable.dart';
import 'package:vector_math/vector_math.dart';

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

class Report extends Equatable implements Comparable<Report> {
  // This is unique and autoincrements.
  final int id;
  final ProblemCategory category;
  final num latitude;
  final num longitude;
  final String description;
  final bool verified;
  final ProgressStatus progress;

  const Report(
      {required this.id,
      required this.category,
      required this.latitude,
      required this.longitude,
      this.description = '',
      this.verified = false,
      this.progress = ProgressStatus.opened});

  Report.fromEntity(Map<String, dynamic> entity)
      : id = entity['id'] as int,
        category = ProblemCategory.fromString(entity['category']),
        latitude = entity['latitude'] as num,
        longitude = entity['longitude'] as num,
        description = entity['description'],
        verified = entity['verified'] as bool,
        progress = ProgressStatus.fromString(entity['progress']);

  Map<String, dynamic> toEntity() => {
        'id': id,
        'category': category.name,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'verified': verified,
        'progress': progress.name
      };

  // This might go unusued; delete if unnecessary
  Vector2 get geoVector => Vector2(longitude.toDouble(), latitude.toDouble());

  @override
  List<Object> get props => [id];

  @override
  int compareTo(Report other) => id.compareTo(other.id);
}
