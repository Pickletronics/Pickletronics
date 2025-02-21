class Impact {
  final List<double> accelerationMagnitudes;
  final double impactStrength;
  final double impactRotation;
  final double maxRotation;

  Impact({
    required this.accelerationMagnitudes,
    required this.impactStrength,
    required this.impactRotation,
    required this.maxRotation,
  });

  Map<String, dynamic> toJson() => {
    'accelerationMagnitudes': accelerationMagnitudes,
    'impactStrength': impactStrength,
    'impactRotation': impactRotation,
    'maxRotation': maxRotation,
  };

  factory Impact.fromJson(Map<String, dynamic> json) => Impact(
    accelerationMagnitudes: (json['accelerationMagnitudes'] as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList(),
    impactStrength: (json['impactStrength'] as num).toDouble(),
    impactRotation: (json['impactRotation'] as num).toDouble(),
    maxRotation: (json['maxRotation'] as num).toDouble(),
  );

  @override
  String toString() {
    return 'Impact(acceleration: $accelerationMagnitudes, strength: $impactStrength, rotation: $impactRotation, maxRotation: $maxRotation)';
  }
}
