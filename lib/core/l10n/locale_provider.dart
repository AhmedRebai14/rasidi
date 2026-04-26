import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/providers/settings_providers.dart';
import 'app_translations.dart';

/// Convenience provider — returns a translate function bound to current language
final tProvider = Provider<String Function(String)>((ref) {
  final lang = ref.watch(settingsProvider).language;
  return (key) => AppTranslations.t(key, lang);
});
