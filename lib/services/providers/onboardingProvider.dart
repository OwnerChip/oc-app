import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStatus {
  final bool showTutorialNextTime;
  final bool showedTutorial;

  const OnboardingStatus({
    required this.showTutorialNextTime,
    this.showedTutorial = false,
  });

  OnboardingStatus copyWith({
    bool? showTutorialNextTime,
    bool? showedTutorial,
  }) {
    return OnboardingStatus(
      showTutorialNextTime: showTutorialNextTime ?? this.showTutorialNextTime,
      showedTutorial: showedTutorial ?? this.showedTutorial,
    );
  }
}

class OnboardingProvider extends StateNotifier<AsyncValue<OnboardingStatus>> {
  OnboardingProvider() : super(const AsyncLoading());

  static const _showTutorialNextTimeKey = 'showTutorialNextTime';

  Future<void> fetchStatus() async {
    state = const AsyncLoading();

    final sharedPrefs = await SharedPreferences.getInstance();

    state = AsyncData(OnboardingStatus(
      showTutorialNextTime:
          sharedPrefs.getBool(_showTutorialNextTimeKey) ?? true,
    ));
  }

  Future<void> showedTutorial() async {
    final current = state.value;

    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(
      showedTutorial: true,
    ));
  }

  Future<void> updateShowTutorialNextTime(bool value) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool(_showTutorialNextTimeKey, value);

    state = AsyncData(state.value?.copyWith(showTutorialNextTime: value) ??
        OnboardingStatus(showTutorialNextTime: value));
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingProvider, AsyncValue<OnboardingStatus>>(
  (ref) => OnboardingProvider()..fetchStatus(),
);
