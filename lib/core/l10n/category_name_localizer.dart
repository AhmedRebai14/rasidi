String localizeCategoryName(String name, String Function(String) t) {
  switch (name.trim().toLowerCase()) {
    case 'food':
      return t('cat_food');
    case 'transport':
      return t('cat_transport');
    case 'rent':
      return t('cat_rent');
    case 'bills':
      return t('cat_bills');
    case 'shopping':
      return t('cat_shopping');
    case 'health':
      return t('cat_health');
    case 'entertainment':
      return t('cat_entertainment');
    case 'salary':
      return t('cat_salary');
    case 'freelance':
      return t('cat_freelance');
    case 'gift':
      return t('cat_gift');
    case 'other':
      return t('cat_other');
    case 'unknown':
      return t('cat_unknown');
    default:
      return name;
  }
}
