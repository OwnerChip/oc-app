import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenUserComplete.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/OnboardingCreatorCompleteButton.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/OnboardingScreenUserStep.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/OnboardingVideoPlayer.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/OnboardingYoutubeCover.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreenWithStepsArguments {
  final String title;
  final List<Widget Function(BuildContext context)> stepBuilders;
  final Widget Function(BuildContext context) completedButtonBuilder;

  const OnboardingScreenWithStepsArguments({
    required this.title,
    required this.stepBuilders,
    required this.completedButtonBuilder,
  });

  factory OnboardingScreenWithStepsArguments.userTutorial(
          BuildContext context) =>
      OnboardingScreenWithStepsArguments(
          title: context.loc.onboardingUserPageTitle,
          stepBuilders: [
            (BuildContext context) => OnboardingScreenUserStep(
                  title: context.loc.onboardingUserPageStep1Title,
                  subtitle: context.loc.onboardingUserPageStep1Subtitle,
                  content: (context) => OnboardingVideoPlayer(
                    asset:
                        'assets/images/common/onboarding_step1_${Platform.isAndroid ? "android" : "ios"}.mp4',
                  ),
                ),
            (BuildContext context) => OnboardingScreenUserStep(
                  title: context.loc.onboardingUserPageStep2Title,
                  subtitle: context.loc.onboardingUserPageStep2Subtitle,
                  content: (context) => const OnboardingVideoPlayer(
                    asset: 'assets/images/common/onboarding_step2.mp4',
                  ),
                ),
          ],
          completedButtonBuilder: (BuildContext context) => CustomRoundedButton(
                text: context.loc.onboardingUserPageCompleteButtonTitle,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                      OnboardingScreenUserComplete.routeName);
                },
              ));

  factory OnboardingScreenWithStepsArguments.creatorTutorial(
          BuildContext context) =>
      OnboardingScreenWithStepsArguments(
        title: context.loc.onboardingCreatorPageTitle,
        stepBuilders: [
          (context) => OnboardingScreenUserStep(
                title: context.loc.onboardingCreatorStep1Title,
                subtitle: context.loc.onboardingCreatorStep1SubTitle,
                content: (context) => Expanded(
                  child:
                      Image.asset('assets/images/common/onboarding_step3.png'),
                ),
                footer: (BuildContext context) => CustomRoundedButton(
                  backgroundColor:
                      CustomColors(dotenv.get('APP_ID')).accentColor,
                  borderColor: CustomColors(dotenv.get('APP_ID')).accentColor,
                  onPressed: () {
                    try {
                      launchUrl(
                        Uri.parse(context.loc.orderChipsUrl),
                      );
                    } catch (e, stackTrace) {
                      Sentry.captureException(e, stackTrace: stackTrace);
                    }
                  },
                  text: context.loc.onboardingCreatorStep1OrderButtonTitle,
                ),
              ),
          (context) => OnboardingScreenUserStep(
                title: context.loc.onboardingCreatorStep2Title,
                content: (context) => Expanded(
                  child: Image.asset(
                    'assets/images/common/onboarding_step4.png',
                  ),
                ),
                subtitle: context.loc.onboardingCreatorStep2SubTitle,
              ),
          (context) => OnboardingScreenUserStep(
                content: (context) => OnboardingYoutubeCover(
                  url: context.loc.onboardingCreatorStep3YoutubeVideoURL,
                ),
                title: context.loc.onboardingCreatorStep3Title,
                subtitle: context.loc.onboardingCreatorStep3SubTitle,
              ),
        ],
        completedButtonBuilder: (context) =>
            const OnboardingCreatorCompleteButton(),
      );
}

class OnboardingScreenWithSteps extends StatefulWidget {
  const OnboardingScreenWithSteps({
    super.key,
  });

  static const routeName = '/onboardingWithSteps';

  @override
  State<OnboardingScreenWithSteps> createState() =>
      _OnboardingScreenWithStepsState();
}

class _OnboardingScreenWithStepsState extends State<OnboardingScreenWithSteps> {
  String title = '';
  final List<Widget Function(BuildContext context)> _steps = [];

  Widget Function(BuildContext context)? _completedButtonBuilder;
  int _currentStep = 0;

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)!.settings.arguments
        as OnboardingScreenWithStepsArguments;
    _steps
      ..clear()
      ..addAll(args.stepBuilders);

    title = args.title;
    _completedButtonBuilder = args.completedButtonBuilder;

    if (mounted) {
      setState(() {});
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        showBackButton: false,
        showWalletButton: false,
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 32,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Row(
              children: [
                Text(
                  context.loc.onboardingPagination(_currentStep + 1),
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall!.apply(
                        color: CustomColors(dotenv.get('APP_ID')).accentColor,
                      ),
                ),
                Text(
                  "${_steps.length}",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_currentStep),
                  child: _steps[_currentStep](context),
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            if (_currentStep == _steps.length - 1 &&
                _completedButtonBuilder != null)
              _completedButtonBuilder!(context)
            else
              CustomRoundedButton(
                  text: context.loc.onboardingUsePageNextButtonTitle,
                  onPressed: () {
                    if (_currentStep < _steps.length - 1) {
                      _currentStep++;

                      if (mounted) {
                        setState(() {});
                      }
                    } else {}
                  }),
            const SizedBox(
              height: 12,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentStep == index ? 8 : 6,
                        height: _currentStep == index ? 8 : 6,
                        decoration: BoxDecoration(
                          color: _currentStep == index
                              ? CustomColors(dotenv.get('APP_ID')).accentColor
                              : CustomColors(dotenv.get('APP_ID'))
                                  .boxDecorationColor,
                          shape: BoxShape.circle,
                        ),
                      )),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      )),
    );
  }
}
