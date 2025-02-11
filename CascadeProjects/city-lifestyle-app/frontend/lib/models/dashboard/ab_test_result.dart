class ABTestResult {
  final String testId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final Map<String, ABTestVariant> variants;
  final Map<String, double> metrics;

  ABTestResult({
    required this.testId,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.variants,
    required this.metrics,
  });

  factory ABTestResult.fromJson(Map<String, dynamic> json) {
    return ABTestResult(
      testId: json['testId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool,
      variants: (json['variants'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          ABTestVariant.fromJson(value as Map<String, dynamic>),
        ),
      ),
      metrics: Map<String, double>.from(
        (json['metrics'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'variants': variants.map((key, value) => MapEntry(key, value.toJson())),
      'metrics': metrics,
    };
  }
}

class ABTestVariant {
  final String id;
  final String name;
  final int assignments;
  final int conversions;
  final double conversionRate;
  final double? uplift;
  final bool isControl;
  final Map<String, double>? confidenceIntervals;

  ABTestVariant({
    required this.id,
    required this.name,
    required this.assignments,
    required this.conversions,
    required this.conversionRate,
    this.uplift,
    required this.isControl,
    this.confidenceIntervals,
  });

  factory ABTestVariant.fromJson(Map<String, dynamic> json) {
    return ABTestVariant(
      id: json['id'] as String,
      name: json['name'] as String,
      assignments: json['assignments'] as int,
      conversions: json['conversions'] as int,
      conversionRate: (json['conversionRate'] as num).toDouble(),
      uplift: json['uplift'] != null ? (json['uplift'] as num).toDouble() : null,
      isControl: json['isControl'] as bool,
      confidenceIntervals: json['confidenceIntervals'] != null
          ? Map<String, double>.from(
              (json['confidenceIntervals'] as Map).map(
                (key, value) =>
                    MapEntry(key as String, (value as num).toDouble()),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'assignments': assignments,
      'conversions': conversions,
      'conversionRate': conversionRate,
      'uplift': uplift,
      'isControl': isControl,
      'confidenceIntervals': confidenceIntervals,
    };
  }
}
