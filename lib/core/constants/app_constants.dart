/// Application-wide constants for Rasidi
class AppConstants {
  AppConstants._();

  static const String appName = 'رصيدي';
  static const String appNameLatin = 'Rasidi';
  static const String appTagline = 'Track your month, own your money';
  static const String appTaglineAr = 'تتبع شهرك، امتلك مالك';

  // Onboarding preference key
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Default currency
  static const String defaultCurrency = 'DA';

  // Default language
  static const String defaultLanguage = 'ar';

  // Recent transactions count on home
  static const int recentTransactionsCount = 5;

  // Quick amount chips for transaction input
  static const List<double> quickAmounts = [100, 500, 1000, 5000];

  // Analytics - months for history chart
  static const int historyMonthsCount = 6;

  // Budget warning thresholds
  static const double budgetWarningThreshold = 0.80;
  static const double budgetCriticalThreshold = 1.00;

  // Balance health thresholds (percentage of initial balance)
  static const double balanceHealthyThreshold = 0.20;

  // PIN length
  static const int pinLength = 4;

  // Currency options for onboarding
  static const List<String> currencyOptions = ['DA', 'TND', '\$', '€', 'MAD'];

  // Recurring intervals labels
  static const Map<String, String> recurringLabels = {
    'daily': 'يومياً / Daily',
    'weekly': 'أسبوعياً / Weekly',
    'monthly': 'شهرياً / Monthly',
  };
}
