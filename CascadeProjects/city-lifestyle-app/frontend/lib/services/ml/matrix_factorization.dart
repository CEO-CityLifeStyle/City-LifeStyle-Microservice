import 'dart:math' as math;
import 'package:collection/collection.dart';

class MatrixFactorization {
  final int numFactors;
  final double learningRate;
  final double regularization;
  final int maxIterations;
  final double convergenceThreshold;

  MatrixFactorization({
    this.numFactors = 10,
    this.learningRate = 0.005,
    this.regularization = 0.02,
    this.maxIterations = 100,
    this.convergenceThreshold = 0.001,
  });

  /// Trains the model using Stochastic Gradient Descent
  Map<String, List<double>> factorizeMatrix({
    required Map<String, Map<String, double>> ratings,
    required List<String> userIds,
    required List<String> itemIds,
  }) {
    final random = math.Random(42); // Fixed seed for reproducibility
    final userFactors = <String, List<double>>{};
    final itemFactors = <String, List<double>>{};

    // Initialize factors with small random values
    for (final userId in userIds) {
      userFactors[userId] = List.generate(
        numFactors,
        (_) => random.nextDouble() * 0.1,
      );
    }

    for (final itemId in itemIds) {
      itemFactors[itemId] = List.generate(
        numFactors,
        (_) => random.nextDouble() * 0.1,
      );
    }

    double prevError = double.infinity;
    int iteration = 0;

    while (iteration < maxIterations) {
      double error = 0;

      // Iterate through all ratings
      for (final userId in ratings.keys) {
        final userRatings = ratings[userId]!;
        for (final itemId in userRatings.keys) {
          final rating = userRatings[itemId]!;
          final prediction = _predictRating(
            userFactors[userId]!,
            itemFactors[itemId]!,
          );

          final diff = rating - prediction;
          error += diff * diff;

          // Update user factors
          for (var f = 0; f < numFactors; f++) {
            final userFactor = userFactors[userId]![f];
            final itemFactor = itemFactors[itemId]![f];

            userFactors[userId]![f] += learningRate *
                (2 * diff * itemFactor - 2 * regularization * userFactor);
            itemFactors[itemId]![f] += learningRate *
                (2 * diff * userFactor - 2 * regularization * itemFactor);
          }
        }
      }

      // Add regularization term to error
      for (final factors in [...userFactors.values, ...itemFactors.values]) {
        error += regularization *
            factors.map((f) => f * f).reduce((a, b) => a + b);
      }

      // Check for convergence
      if ((prevError - error).abs() < convergenceThreshold) {
        break;
      }

      prevError = error;
      iteration++;
    }

    return {...userFactors, ...itemFactors};
  }

  /// Predicts the rating for a user-item pair
  double _predictRating(List<double> userFactors, List<double> itemFactors) {
    return userFactors
        .mapIndexed((i, uf) => uf * itemFactors[i])
        .reduce((a, b) => a + b);
  }

  /// Gets top N recommendations for a user
  List<String> getTopNRecommendations({
    required String userId,
    required Map<String, List<double>> factors,
    required List<String> itemIds,
    required Set<String> excludeItems,
    int n = 10,
  }) {
    final userFactors = factors[userId]!;
    final recommendations = <String, double>{};

    for (final itemId in itemIds) {
      if (excludeItems.contains(itemId)) continue;

      final itemFactors = factors[itemId]!;
      final predictedRating = _predictRating(userFactors, itemFactors);
      recommendations[itemId] = predictedRating;
    }

    return recommendations.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(n)
        .map((e) => e.key)
        .toList();
  }

  List<String> getTopNRecommendationsAlternative({
    required int userId,
    required int n,
    required Map<int, List<double>> _userFactors,
    required Map<int, List<double>> _itemFactors,
    required List<int> _itemIds,
  }) {
    final userFactors = _userFactors[userId]!;
    final scores = _itemFactors.values.map((itemVec) => _dotProduct(userFactors, itemVec)).toList();
    
    final rankedItems = scores
      .asMap()
      .entries
      .sorted((a, b) => b.value.compareTo(a.value))
      .take(n)
      .map((e) => _itemIds[e.key])
      .toList();

    return rankedItems.map((e) => e.toString()).toList();
  }

  double _dotProduct(List<double> vector1, List<double> vector2) {
    return vector1
        .mapIndexed((i, uf) => uf * vector2[i])
        .reduce((a, b) => a + b);
  }

  /// Calculates the RMSE (Root Mean Square Error) for the model
  double calculateRMSE({
    required Map<String, Map<String, double>> actualRatings,
    required Map<String, List<double>> factors,
  }) {
    double sumSquaredError = 0;
    int count = 0;

    for (final userId in actualRatings.keys) {
      final userRatings = actualRatings[userId]!;
      for (final itemId in userRatings.keys) {
        final actualRating = userRatings[itemId]!;
        final predictedRating = _predictRating(
          factors[userId]!,
          factors[itemId]!,
        );

        sumSquaredError += math.pow(actualRating - predictedRating, 2);
        count++;
      }
    }

    return math.sqrt(sumSquaredError / count);
  }
}
