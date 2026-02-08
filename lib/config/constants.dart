/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'BudgetWise';
  static const String appVersion = '1.0.0';

  // Default Settings
  static const String defaultCurrency = 'GBP';
  static const String defaultLocale = 'en_GB';

  // Currency Symbols
  static const Map<String, String> currencySymbols = {
    'GBP': '\u00A3',
    'USD': '\$',
    'EUR': '\u20AC',
    'JPY': '\u00A5',
    'INR': '\u20B9',
  };

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Limits
  static const int maxCategoriesPerMonth = 20;
  static const int maxItemsPerCategory = 30;
  static const int maxIncomeSourcesPerMonth = 10;
  static const double maxTransactionAmount = 999999999.99;
}

/// Default category templates
const List<Map<String, dynamic>> defaultCategories = [
  {
    'name': 'Housing',
    'icon': 'home',
    'color': '#3B82F6',
    'items': [
      {'name': 'Rent/Mortgage', 'projected': 0},
      {'name': 'Electricity', 'projected': 0},
      {'name': 'Gas', 'projected': 0},
      {'name': 'Water', 'projected': 0},
      {'name': 'Internet', 'projected': 0},
      {'name': 'Council Tax', 'projected': 0},
    ],
  },
  {
    'name': 'Food',
    'icon': 'utensils',
    'color': '#F97316',
    'items': [
      {'name': 'Groceries', 'projected': 0},
      {'name': 'Dining Out', 'projected': 0},
      {'name': 'Coffee', 'projected': 0},
      {'name': 'Takeaway', 'projected': 0},
    ],
  },
  {
    'name': 'Transport',
    'icon': 'car',
    'color': '#22C55E',
    'items': [
      {'name': 'Fuel', 'projected': 0},
      {'name': 'Public Transport', 'projected': 0},
      {'name': 'Uber/Taxi', 'projected': 0},
      {'name': 'Parking', 'projected': 0},
      {'name': 'Car Insurance', 'projected': 0},
      {'name': 'Car Maintenance', 'projected': 0},
    ],
  },
  {
    'name': 'Personal',
    'icon': 'shopping-bag',
    'color': '#EC4899',
    'items': [
      {'name': 'Clothing', 'projected': 0},
      {'name': 'Haircut', 'projected': 0},
      {'name': 'Health & Medicine', 'projected': 0},
      {'name': 'Personal Care', 'projected': 0},
    ],
  },
  {
    'name': 'Entertainment',
    'icon': 'gamepad-2',
    'color': '#EAB308',
    'items': [
      {'name': 'Games', 'projected': 0},
      {'name': 'Movies', 'projected': 0},
      {'name': 'Events', 'projected': 0},
      {'name': 'Hobbies', 'projected': 0},
    ],
  },
  {
    'name': 'Savings',
    'icon': 'piggy-bank',
    'color': '#14B8A6',
    'items': [
      {'name': 'Emergency Fund', 'projected': 0},
      {'name': 'Investments', 'projected': 0},
      {'name': 'Holiday Fund', 'projected': 0},
    ],
  },
];

/// Budget templates for different user types
const Map<String, List<String>> budgetTemplates = {
  'individual': [
    'Housing',
    'Food',
    'Transport',
    'Personal',
    'Entertainment',
    'Savings',
  ],
  'student': [
    'Housing',
    'Food',
    'Transport',
    'Personal',
    'Education',
    'Entertainment',
  ],
  'family': [
    'Housing',
    'Food',
    'Transport',
    'Personal',
    'Children',
    'Healthcare',
    'Savings',
  ],
  'freelancer': [
    'Housing',
    'Food',
    'Transport',
    'Personal',
    'Business Expenses',
    'Taxes',
    'Savings',
  ],
};

/// Available category icons
const List<String> categoryIcons = [
  'home',
  'utensils',
  'car',
  'tv',
  'shopping-bag',
  'gamepad-2',
  'piggy-bank',
  'graduation-cap',
  'heart',
  'briefcase',
  'plane',
  'gift',
  'credit-card',
  'wallet',
  'landmark',
  'baby',
  'dog',
  'dumbbell',
  'music',
  'book',
];

/// Available category colors
const List<String> categoryColors = [
  '#3B82F6', // Blue
  '#F97316', // Orange
  '#22C55E', // Green
  '#A855F7', // Purple
  '#EC4899', // Pink
  '#EAB308', // Yellow
  '#14B8A6', // Teal
  '#EF4444', // Red
  '#6366F1', // Indigo
  '#84CC16', // Lime
  '#F59E0B', // Amber
  '#06B6D4', // Cyan
];
