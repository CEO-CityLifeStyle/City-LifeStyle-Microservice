class RecommendationMetrics {
  final int totalRecommendations;
  final double clickThroughRate;
  final double conversionRate;
  final Map<String, CategoryMetrics> categoryMetrics;
  final Map<String, double> timeSeriesData;
  final List<AlgorithmPerformance> algorithmPerformance;

  RecommendationMetrics({
    required this.totalRecommendations,
    required this.clickThroughRate,
    required this.conversionRate,
    required this.categoryMetrics,
    required this.timeSeriesData,
    required this.algorithmPerformance,
  });

  factory RecommendationMetrics.fromJson(Map<String, dynamic> json) {
    return RecommendationMetrics(
      totalRecommendations: json['totalRecommendations'] as int,
      clickThroughRate: (json['clickThroughRate'] as num).toDouble(),
      conversionRate: (json['conversionRate'] as num).toDouble(),
      categoryMetrics: (json['categoryMetrics'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          CategoryMetrics.fromJson(value as Map<String, dynamic>),
        ),
      ),
      timeSeriesData: Map<String, double>.from(
        (json['timeSeriesData'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      algorithmPerformance: (json['algorithmPerformance'] as List)
          .map((e) => AlgorithmPerformance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRecommendations': totalRecommendations,
      'clickThroughRate': clickThroughRate,
      'conversionRate': conversionRate,
      'categoryMetrics':
          categoryMetrics.map((key, value) => MapEntry(key, value.toJson())),
      'timeSeriesData': timeSeriesData,
      'algorithmPerformance':
          algorithmPerformance.map((e) => e.toJson()).toList(),
    };
  }
}

class CategoryMetrics {
  final int recommendations;
  final double clickThroughRate;
  final double conversionRate;
  final double relevanceScore;

  CategoryMetrics({
    required this.recommendations,
    required this.clickThroughRate,
    required this.conversionRate,
    required this.relevanceScore,
  });

  factory CategoryMetrics.fromJson(Map<String, dynamic> json) {
    return CategoryMetrics(
      recommendations: json['recommendations'] as int,
      clickThroughRate: (json['clickThroughRate'] as num).toDouble(),
      conversionRate: (json['conversionRate'] as num).toDouble(),
      relevanceScore: (json['relevanceScore'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations,
      'clickThroughRate': clickThroughRate,
      'conversionRate': conversionRate,
      'relevanceScore': relevanceScore,
    };
  }
}

class AlgorithmPerformance {
  final String algorithmId;
  final String name;
  final double precision;
  final double recall;
  final double f1Score;
  final double meanReciprocalRank;
  final Map<String, double> metrics;

  AlgorithmPerformance({
    required this.algorithmId,
    required this.name,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.meanReciprocalRank,
    required this.metrics,
  });

  factory AlgorithmPerformance.fromJson(Map<String, dynamic> json) {
    return AlgorithmPerformance(
      algorithmId: json['algorithmId'] as String,
      name: json['name'] as String,
      precision: (json['precision'] as num).toDouble(),
      recall: (json['recall'] as num).toDouble(),
      f1Score: (json['f1Score'] as num).toDouble(),
      meanReciprocalRank: (json['meanReciprocalRank'] as num).toDouble(),
      metrics: Map<String, double>.from(
        (json['metrics'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'algorithmId': algorithmId,
      'name': name,
      'precision': precision,
      'recall': recall,
      'f1Score': f1Score,
      'meanReciprocalRank': meanReciprocalRank,
      'metrics': metrics,
    };
  }
}
