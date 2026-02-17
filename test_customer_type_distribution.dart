import 'dart:math';

/// Test script to verify customer type distribution
/// Run with: dart test_customer_type_distribution.dart

String getRandomCustomerType() {
  final random = Random();
  final value = random.nextDouble(); // 0.0 to 1.0

  if (value < 0.40) {
    return 'enterprise';
  } else if (value < 0.60) {
    return 'small-plan';
  } else if (value < 0.80) {
    return 'medium-plan';
  } else {
    return 'large-plan';
  }
}

void main() {
  const iterations = 10000;
  final counts = <String, int>{};

  // Generate random customer types
  for (var i = 0; i < iterations; i++) {
    final type = getRandomCustomerType();
    counts[type] = (counts[type] ?? 0) + 1;
  }

  // Print results
  print('Customer Type Distribution Test ($iterations iterations):');
  print('─' * 60);

  counts.forEach((type, count) {
    final percentage = (count / iterations * 100).toStringAsFixed(2);
    final bar = '█' * (count ~/ (iterations / 50));
    print('$type'.padRight(15) + '$count'.padLeft(6) + ' ($percentage%) $bar');
  });

  print('─' * 60);
  print('\nExpected Distribution:');
  print('enterprise:    40%');
  print('small-plan:    20%');
  print('medium-plan:   20%');
  print('large-plan:    20%');
}
