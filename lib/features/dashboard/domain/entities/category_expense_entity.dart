class CategoryExpenseEntity {
  final String category;
  final double amount;
  final double percentage;
  final int count;

  const CategoryExpenseEntity({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });

  CategoryExpenseEntity copyWith({
    String? category,
    double? amount,
    double? percentage,
    int? count,
  }) {
    return CategoryExpenseEntity(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      count: count ?? this.count,
    );
  }
}
