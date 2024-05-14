
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenWithSteps.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/onboarding_screen_user_step.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/onboarding_youtube_cover.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreenUserComplete extends StatelessWidget {
  const OnboardingScreenUserComplete({super.key});

  static const routeName = '/onboardingUserComplete';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        showBackButton: false,
        showWalletButton: false,
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          children: [
            const Spacer(
              flex: 4,
            ),
            Text(
              context.loc.onboardingUserCompleteCreatorPageTitle,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              context.loc.onboardingUserCompleteCreatorPageSubtitle,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 24,
            ),
            CustomRoundedButton(
                text: context.loc.onboardingUserCompleteCreatorButtonTitle,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                      OnboardingScreenWithSteps.routeName,
                      arguments: OnboardingScreenWithStepsArguments(
                        title: context.loc.onboardingCreatorPageTitle,
                        stepBuilders: [
                          (context) => OnboardingScreenUserStep(
                                title: context.loc.onboardingCreatorStep1Title,
                                subtitle:
                                    context.loc.onboardingCreatorStep1SubTitle,
                                content: (context) => Expanded(
                                  child: Image.asset(
                                      'assets/images/common/onboarding_step3.png'),
                                ),
                                footer: (BuildContext context) =>
                                    CustomRoundedButton(
                                  backgroundColor:
                                      CustomColors(dotenv.get('APP_ID'))
                                          .accentColor,
                                  borderColor:
                                      CustomColors(dotenv.get('APP_ID'))
                                          .accentColor,
                                  onPressed: () {
                                    try {
                                      launchUrl(
                                        Uri.parse(context.loc.orderChipsUrl),
                                      );
                                    } catch (e, stackTrace) {
                                      Sentry.captureException(e,
                                          stackTrace: stackTrace);
                                    }
                                  },
                                  text: context.loc
                                      .onboardingCreatorStep1OrderButtonTitle,
                                ),
                              ),
                          (context) => OnboardingScreenUserStep(
                                title: context.loc.onboardingCreatorStep2Title,
                                content: (context) => Expanded(
                                  child: Image.asset(
                                    'assets/images/common/onboarding_step4.png',
                                  ),
                                ),
                                subtitle:
                                    context.loc.onboardingCreatorStep2SubTitle,
                              ),
                          (context) => OnboardingScreenUserStep(
                                content: (context) => OnboardingYoutubeCover(
                                  url: context.loc
                                      .onboardingCreatorStep3YoutubeVideoURL,
                                ),
                                title: context.loc.onboardingCreatorStep3Title,
                                subtitle:
                                    context.loc.onboardingCreatorStep3SubTitle,
                              ),
                        ],
                        completedButtonBuilder: (context) =>
                            CustomRoundedButton(
                                text: context
                                    .loc.onboardingCreatorCompleteButtonTitle,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }),
                      ));
                }),
            const Spacer(
              flex: 3,
            ),
            Icon(
              Icons.celebration_outlined,
              size: 128,
              color: CustomColors(dotenv.get('APP_ID')).accentColor,
            ),
            const SizedBox(
              height: 48,
            ),
            Text(
              context.loc.onboardingUserCompleteTitle,
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(
              height: 24,
            ),
            Text(
              context.loc.onboardingUserCompleteSubtitle,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 24,
            ),
            CustomRoundedButton(
              text: context.loc.onboardingUserCompleteButtonTitle,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(
              height: 48,
            ),
          ],
        ),
      )),
    );
  }
}
