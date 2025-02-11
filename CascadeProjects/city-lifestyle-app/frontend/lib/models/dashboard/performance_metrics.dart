class PerformanceMetrics {
  final int totalUsers;
  final int activeUsers;
  final int totalPlaces;
  final double averageRating;
  final Map<String, int> userGrowth;
  final Map<String, double> engagementRate;
  final Map<String, int> placeVisits;

  PerformanceMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPlaces,
    required this.averageRating,
    required this.userGrowth,
    required this.engagementRate,
    required this.placeVisits,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      totalPlaces: json['totalPlaces'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      userGrowth: Map<String, int>.from(json['userGrowth'] as Map),
      engagementRate: Map<String, double>.from(
        (json['engagementRate'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      placeVisits: Map<String, int>.from(json['placeVisits'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalPlaces': totalPlaces,
      'averageRating': averageRating,
      'userGrowth': userGrowth,
      'engagementRate': engagementRate,
      'placeVisits': placeVisits,
    };
  }

  PerformanceMetrics copyWith({
    int? totalUsers,
    int? activeUsers,
    int? totalPlaces,
    double? averageRating,
    Map<String, int>? userGrowth,
    Map<String, double>? engagementRate,
    Map<String, int>? placeVisits,
  }) {
    return PerformanceMetrics(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      totalPlaces: totalPlaces ?? this.totalPlaces,
      averageRating: averageRating ?? this.averageRating,
      userGrowth: userGrowth ?? this.userGrowth,
      engagementRate: engagementRate ?? this.engagementRate,
      placeVisits: placeVisits ?? this.placeVisits,
    );
  }
}
