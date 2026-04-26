import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../features/categories/data/category_model.dart';
import '../../../features/transactions/data/transaction_model.dart';
import '../../../features/session/data/monthly_session.dart';
import '../../../features/savings/data/saving_model.dart';
import 'package:uuid/uuid.dart';

/// Seeds the database with default categories and (in debug mode) sample data
class SeedDataService {
  SeedDataService._();

  static final _uuid = Uuid();

  /// Run on first launch to populate default categories
  static Future<void> seedDefaultCategories() async {
    final box = Hive.box<CategoryModel>(HiveBoxes.categories);
    if (box.isNotEmpty) return; // Already seeded

    final defaultCategories = _buildDefaultCategories();
    for (final cat in defaultCategories) {
      await box.put(cat.id, cat);
    }
  }

  static List<CategoryModel> _buildDefaultCategories() {
    return [
      // Expense categories
      CategoryModel(
        id: _uuid.v4(),
        name: 'Food',
        type: TransactionType.expense,
        icon: '${Icons.fastfood.codePoint}',
        color: 0xFFE53935,
        isDefault: true,
        sortOrder: 0,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Transport',
        type: TransactionType.expense,
        icon: '${Icons.directions_car.codePoint}',
        color: 0xFFFB8C00,
        isDefault: true,
        sortOrder: 1,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Rent',
        type: TransactionType.expense,
        icon: '${Icons.home.codePoint}',
        color: 0xFF8E24AA,
        isDefault: true,
        sortOrder: 2,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Bills',
        type: TransactionType.expense,
        icon: '${Icons.lightbulb.codePoint}',
        color: 0xFFFDD835,
        isDefault: true,
        sortOrder: 3,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Shopping',
        type: TransactionType.expense,
        icon: '${Icons.shopping_bag.codePoint}',
        color: 0xFFE91E63,
        isDefault: true,
        sortOrder: 4,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Health',
        type: TransactionType.expense,
        icon: '${Icons.medication.codePoint}',
        color: 0xFF43A047,
        isDefault: true,
        sortOrder: 5,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Entertainment',
        type: TransactionType.expense,
        icon: '${Icons.movie.codePoint}',
        color: 0xFF1E88E5,
        isDefault: true,
        sortOrder: 6,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Other',
        type: TransactionType.expense,
        icon: '${Icons.category.codePoint}',
        color: 0xFF757575,
        isDefault: true,
        sortOrder: 7,
      ),
      // Income categories
      CategoryModel(
        id: _uuid.v4(),
        name: 'Salary',
        type: TransactionType.income,
        icon: '${Icons.work.codePoint}',
        color: 0xFF2E7D32,
        isDefault: true,
        sortOrder: 0,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Freelance',
        type: TransactionType.income,
        icon: '${Icons.laptop.codePoint}',
        color: 0xFF00838F,
        isDefault: true,
        sortOrder: 1,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Gift',
        type: TransactionType.income,
        icon: '${Icons.card_giftcard.codePoint}',
        color: 0xFFF06292,
        isDefault: true,
        sortOrder: 2,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: 'Other',
        type: TransactionType.income,
        icon: '${Icons.category.codePoint}',
        color: 0xFF757575,
        isDefault: true,
        sortOrder: 3,
      ),
    ];
  }

  /// Seed debug data (development/testing only)
  static Future<void> seedDebugData() async {
    final sessionBox = Hive.box<MonthlySession>(HiveBoxes.sessions);
    final txBox = Hive.box<TransactionModel>(HiveBoxes.transactions);
    final catBox = Hive.box<CategoryModel>(HiveBoxes.categories);
    final savingBox = Hive.box<SavingModel>(HiveBoxes.savings);

    // Only seed once
    if (sessionBox.isNotEmpty) return;

    // Ensure categories are seeded
    await seedDefaultCategories();

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final sessionId = _uuid.v4();

    // Create open session for current month
    final session = MonthlySession(
      id: sessionId,
      month: monthKey,
      initialBalance: 85000.0,
      finalBalance: 0,
      status: SessionStatus.open,
      createdAt: now.copyWith(day: 1),
    );
    await sessionBox.put(session.id, session);

    // Get category ids from box
    final expCats = catBox.values
        .where((c) => c.type == TransactionType.expense)
        .toList();
    final incCats = catBox.values
        .where((c) => c.type == TransactionType.income)
        .toList();

    if (expCats.isEmpty || incCats.isEmpty) return;

    // 15 sample transactions
    final sampleTransactions = [
      TransactionModel(
        id: _uuid.v4(),
        amount: 85000.0,
        type: TransactionType.income,
        categoryId: incCats[0].id, // Salary
        date: now.copyWith(day: 1),
        note: 'Monthly Salary',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 25000.0,
        type: TransactionType.expense,
        categoryId: expCats[2].id, // Rent
        date: now.copyWith(day: 2),
        note: 'Monthly Rent',
        sessionId: sessionId,
        isRecurring: true,
        recurringInterval: RecurringInterval.monthly,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 1200.0,
        type: TransactionType.expense,
        categoryId: expCats[0].id, // Food
        date: now.copyWith(day: 3),
        note: 'Groceries',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 800.0,
        type: TransactionType.expense,
        categoryId: expCats[1].id, // Transport
        date: now.copyWith(day: 5),
        note: 'Fuel',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 3000.0,
        type: TransactionType.expense,
        categoryId: expCats[3].id, // Bills
        date: now.copyWith(day: 5),
        note: 'Electricity + Internet',
        sessionId: sessionId,
        isRecurring: true,
        recurringInterval: RecurringInterval.monthly,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 650.0,
        type: TransactionType.expense,
        categoryId: expCats[0].id, // Food
        date: now.copyWith(day: 7),
        note: 'Restaurant',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 2500.0,
        type: TransactionType.expense,
        categoryId: expCats[4].id, // Shopping
        date: now.copyWith(day: 9),
        note: 'Clothes',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 5000.0,
        type: TransactionType.income,
        categoryId: incCats[1].id, // Freelance
        date: now.copyWith(day: 10),
        note: 'Web project',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 900.0,
        type: TransactionType.expense,
        categoryId: expCats[5].id, // Health
        date: now.copyWith(day: 12),
        note: 'Pharmacy',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 1500.0,
        type: TransactionType.expense,
        categoryId: expCats[6].id, // Entertainment
        date: now.copyWith(day: 14),
        note: 'Cinema + dinner',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 400.0,
        type: TransactionType.expense,
        categoryId: expCats[0].id, // Food
        date: now.copyWith(day: 15),
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 3000.0,
        type: TransactionType.income,
        categoryId: incCats[2].id, // Gift
        date: now.copyWith(day: 16),
        note: 'Birthday gift',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 1100.0,
        type: TransactionType.expense,
        categoryId: expCats[1].id, // Transport
        date: now.copyWith(day: 18),
        note: 'Taxi rides',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 750.0,
        type: TransactionType.expense,
        categoryId: expCats[4].id, // Shopping
        date: now.copyWith(day: 20),
        note: 'Household items',
        sessionId: sessionId,
      ),
      TransactionModel(
        id: _uuid.v4(),
        amount: 500.0,
        type: TransactionType.expense,
        categoryId: expCats[7].id, // Other
        date: now.copyWith(day: 22),
        note: 'Miscellaneous',
        sessionId: sessionId,
      ),
    ];

    for (final tx in sampleTransactions) {
      await txBox.put(tx.id, tx);
    }

    // One saving from last month
    final lastMonthSession = _uuid.v4();
    final saving = SavingModel(
      id: _uuid.v4(),
      amount: 15000.0,
      date: now.subtract(const Duration(days: 30)),
      sourceSessionId: lastMonthSession,
      note: 'Saved from last month',
    );
    await savingBox.put(saving.id, saving);
  }
}

extension on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
    );
  }
}
