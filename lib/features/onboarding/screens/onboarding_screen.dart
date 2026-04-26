import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/l10n/app_translations.dart';
import '../../../features/settings/data/app_settings_model.dart';
import '../../../features/settings/providers/settings_providers.dart';
import '../../../shared/services/seed_data_service.dart';

/// 3-screen onboarding carousel shown only on first launch
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedCurrency = 'DA';
  final TextEditingController _customCurrencyController =
      TextEditingController();
  bool _completing = false; // guard against double-tap

  @override
  void dispose() {
    _pageController.dispose();
    _customCurrencyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_completing) return;
    _completing = true;
    // Set currency in settings
    final currency = _selectedCurrency == 'custom'
        ? _customCurrencyController.text.trim().isNotEmpty
            ? _customCurrencyController.text.trim()
            : 'DA'
        : _selectedCurrency;

    await ref.read(settingsProvider.notifier).setCurrency(currency);

    // Seed default categories
    await SeedDataService.seedDefaultCategories();

    // In debug mode, seed sample data
    assert(() {
      SeedDataService.seedDebugData();
      return true;
    }());

    // Mark onboarding as done
    final box = Hive.box<AppSettingsModel>(HiveBoxes.settings);
    await box.put('onboarding_done', AppSettingsModel());

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    String t(String key) => AppTranslations.t(key, lang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(t),
                  _buildPage2(t),
                  _buildPage3(t),
                ],
              ),
            ),
            _buildBottomControls(t),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(77),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ر',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppConstants.appName,
            style: AppTextStyles.balanceHero.copyWith(fontSize: 40),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.appNameLatin,
            style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(t('app_tagline'),
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPage2(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_month, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(t('onboarding_monthly_cycles'),
              style: AppTextStyles.sectionTitle, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _buildCycleStep('1', t('onboarding_step1_title'), t('onboarding_step1_desc')),
          _buildCycleStep('2', t('onboarding_step2_title'), t('onboarding_step2_desc')),
          _buildCycleStep('3', t('onboarding_step3_title'), t('onboarding_step3_desc')),
          _buildCycleStep('4', t('onboarding_step4_title'), t('onboarding_step4_desc')),
        ],
      ),
    );
  }

  Widget _buildCycleStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                Text(description,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.attach_money, size: 80, color: AppColors.primary),
          const SizedBox(height: 32),
          Text(t('onboarding_choose_currency'), style: AppTextStyles.sectionTitle),
          const SizedBox(height: 8),
          Text(t('onboarding_currency_sub'),
              style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ...AppConstants.currencyOptions.map((c) => _buildCurrencyChip(c)),
              _buildCurrencyChip('custom', label: t('onboarding_custom')),
            ],
          ),
          if (_selectedCurrency == 'custom') ...[
            const SizedBox(height: 20),
            TextField(
              controller: _customCurrencyController,
              decoration: InputDecoration(
                hintText: t('onboarding_currency_hint'),
                prefixIcon: const Icon(Icons.currency_exchange),
              ),
              maxLength: 5,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(String currency, {String? label}) {
    final isSelected = _selectedCurrency == currency;
    return GestureDetector(
      onTap: () => setState(() => _selectedCurrency = currency),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(51),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label ?? currency,
          style: AppTextStyles.button.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    ),
                    child: Text(t('onboarding_back')),
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentPage > 0 ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == 2 ? t('onboarding_get_started') : t('onboarding_next')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
