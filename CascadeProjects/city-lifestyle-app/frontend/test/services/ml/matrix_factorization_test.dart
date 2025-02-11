import 'package:flutter_test/flutter_test.dart';
import 'package:city_lifestyle_app/services/ml/matrix_factorization.dart';

void main() {
  group('MatrixFactorization Tests', () {
    late MatrixFactorization mf;
    late Map<String, Map<String, double>> testRatings;
    late List<String> userIds;
    late List<String> itemIds;

    setUp(() {
      mf = MatrixFactorization(
        numFactors: 3,
        learningRate: 0.01,
        regularization: 0.02,
        maxIterations: 50,
        convergenceThreshold: 0.001,
      );

      testRatings = {
        'user1': {'item1': 5.0, 'item2': 3.0, 'item3': 4.0},
        'user2': {'item1': 3.0, 'item2': 4.0, 'item4': 5.0},
        'user3': {'item2': 4.0, 'item3': 5.0, 'item4': 4.0},
      };

      userIds = ['user1', 'user2', 'user3'];
      itemIds = ['item1', 'item2', 'item3', 'item4'];
    });

    test('Matrix Factorization - Model Training', () {
      final factors = mf.factorizeMatrix(
        ratings: testRatings,
        userIds: userIds,
        itemIds: itemIds,
      );

      // Check if factors are generated for all users and items
      for (final userId in userIds) {
        expect(factors[userId], isNotNull);
        expect(factors[userId]!.length, equals(mf.numFactors));
      }

      for (final itemId in itemIds) {
        expect(factors[itemId], isNotNull);
        expect(factors[itemId]!.length, equals(mf.numFactors));
      }
    });

    test('Matrix Factorization - Rating Prediction', () {
      final factors = mf.factorizeMatrix(
        ratings: testRatings,
        userIds: userIds,
        itemIds: itemIds,
      );

      // Test prediction for existing rating
      final userFactors = factors['user1']!;
      final itemFactors = factors['item1']!;
      final prediction = mf._predictRating(userFactors, itemFactors);

      expect(prediction, isNotNull);
      // Prediction should be within reasonable rating bounds
      expect(prediction, greaterThanOrEqualTo(0));
      expect(prediction, lessThanOrEqualTo(6));
    });

    test('Matrix Factorization - Top N Recommendations', () {
      final factors = mf.factorizeMatrix(
        ratings: testRatings,
        userIds: userIds,
        itemIds: itemIds,
      );

      final recommendations = mf.getTopNRecommendations(
        userId: 'user1',
        factors: factors,
        itemIds: itemIds,
        excludeItems: {'item1', 'item2', 'item3'}, // Already rated items
        n: 1,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, equals(1));
      expect(recommendations.first, equals('item4'));
    });

    test('Matrix Factorization - RMSE Calculation', () {
      final factors = mf.factorizeMatrix(
        ratings: testRatings,
        userIds: userIds,
        itemIds: itemIds,
      );

      final rmse = mf.calculateRMSE(
        actualRatings: testRatings,
        factors: factors,
      );

      expect(rmse, isNotNull);
      expect(rmse, isPositive);
      // RMSE should be reasonably low for a well-trained model
      expect(rmse, lessThan(2.0));
    });

    test('Matrix Factorization - Model Convergence', () {
      // Create a simple test case with perfect factorization
      final simpleRatings = {
        'user1': {'item1': 1.0, 'item2': 0.0},
        'user2': {'item1': 0.0, 'item2': 1.0},
      };
      final simpleUserIds = ['user1', 'user2'];
      final simpleItemIds = ['item1', 'item2'];

      final mfConverge = MatrixFactorization(
        numFactors: 2,
        learningRate: 0.01,
        regularization: 0.001,
        maxIterations: 1000,
        convergenceThreshold: 0.0001,
      );

      final factors = mfConverge.factorizeMatrix(
        ratings: simpleRatings,
        userIds: simpleUserIds,
        itemIds: simpleItemIds,
      );

      final rmse = mfConverge.calculateRMSE(
        actualRatings: simpleRatings,
        factors: factors,
      );

      // Model should converge well for this simple case
      expect(rmse, lessThan(0.5));
    });

    test('Matrix Factorization - Parameter Validation', () {
      expect(
        () => MatrixFactorization(numFactors: 0),
        throwsAssertionError,
      );
      expect(
        () => MatrixFactorization(learningRate: 0),
        throwsAssertionError,
      );
      expect(
        () => MatrixFactorization(regularization: -1),
        throwsAssertionError,
      );
      expect(
        () => MatrixFactorization(maxIterations: 0),
        throwsAssertionError,
      );
      expect(
        () => MatrixFactorization(convergenceThreshold: 0),
        throwsAssertionError,
      );
    });
  });
}
