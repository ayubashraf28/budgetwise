const String systemSubscriptionsCategoryName = 'Subscriptions';

const Set<String> _reservedCategoryNames = {
  'subscription',
  'subscriptions',
};

String _normalizeCategoryName(String name) => name.trim().toLowerCase();

bool isReservedCategoryName(String name) {
  return _reservedCategoryNames.contains(_normalizeCategoryName(name));
}

String canonicalizeCategoryName(String name) {
  if (isReservedCategoryName(name)) {
    return systemSubscriptionsCategoryName;
  }
  return name.trim();
}
