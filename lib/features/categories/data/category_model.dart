import 'package:hive/hive.dart';
import '../../transactions/data/transaction_model.dart';

part 'category_model.g.dart';

/// Expense or income category
@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  TransactionType type;

  /// Material icon codepoint as string (e.g. "0xe25a")
  @HiveField(3)
  String icon;

  /// Color stored as ARGB int
  @HiveField(4)
  int color;

  @HiveField(5)
  bool isDefault;

  @HiveField(6)
  bool isFavorite;

  @HiveField(7)
  int sortOrder;

  @HiveField(8)
  bool isArchived;

  /// Optional monthly budget limit
  @HiveField(9)
  double? budgetLimit;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.isFavorite = false,
    this.sortOrder = 0,
    this.isArchived = false,
    this.budgetLimit,
  });

  CategoryModel copyWith({
    String? name,
    String? icon,
    int? color,
    bool? isFavorite,
    int? sortOrder,
    bool? isArchived,
    double? budgetLimit,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      type: type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      budgetLimit: budgetLimit ?? this.budgetLimit,
    );
  }
}
