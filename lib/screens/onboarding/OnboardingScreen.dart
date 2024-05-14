import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenUserComplete.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenWithSteps.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/onboarding_screen_user_step.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/widgets/onboarding_video_player.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Icon(
                      Icons.waving_hand_outlined,
                      size: 128,
                      color: CustomColors(dotenv.get('APP_ID')).accentColor,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                      context.loc.onboardingTitle,
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                    _buildIconTextItem(
                      context,
                      icon: Icon(
                        Icons.verified_user_outlined,
                        size: 48,
                        color:
                            CustomColors(dotenv.get('APP_ID')).headline2Color,
                      ),
                      title: context.loc.onboardingFeatureAuthenticityTitle,
                      subtitle:
                          context.loc.onboardingFeatureAuthenticitySubtitle,
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                    _buildIconTextItem(
                      context,
                      icon: Icon(
                        Icons.star_outline_outlined,
                        size: 48,
                        color:
                            CustomColors(dotenv.get('APP_ID')).headline2Color,
                      ),
                      title: context
                          .loc.onboardingFeatureDigitalExperiencesTitle,
                      subtitle: context
                          .loc.onboardingFeatureDigitalExperiencesSubtitle,
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                    _buildIconTextItem(
                      context,
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        size: 48,
                        color:
                            CustomColors(dotenv.get('APP_ID')).headline2Color,
                      ),
                      title: context.loc.onboardingFeatureSellTitle,
                      subtitle: context.loc.onboardingFeatureSellSubtitle,
                    ),
                    const SizedBox(
                      height: 48,
                    ),
                  ],
                ),
              ),
              CustomRoundedButton(
                text: context.loc.onboardingStartButton,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    OnboardingScreenWithSteps.routeName,
                    arguments: OnboardingScreenWithStepsArguments(
                        title: context.loc.onboardingUserPageTitle,
                        stepBuilders: [
                          (BuildContext context) => OnboardingScreenUserStep(
                                title:
                                    context.loc.onboardingUserPageStep1Title,
                                subtitle: context
                                    .loc.onboardingUserPageStep1Subtitle,
                                content: (context) => OnboardingVideoPlayer(
                                  asset:
                                      'assets/images/common/onboarding_step1_${Platform.isAndroid ? "android" : "ios"}.mp4',
                                ),
                              ),
                          (BuildContext context) => OnboardingScreenUserStep(
                                title:
                                    context.loc.onboardingUserPageStep2Title,
                                subtitle: context
                                    .loc.onboardingUserPageStep2Subtitle,
                                content: (context) =>
                                    const OnboardingVideoPlayer(
                                  asset:
                                      'assets/images/common/onboarding_step2.mp4',
                                ),
                              ),
                        ],
                        completedButtonBuilder: (BuildContext context) =>
                            CustomRoundedButton(
                              text: context
                                  .loc.onboardingUserPageCompleteButtonTitle,
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
                                    OnboardingScreenUserComplete.routeName);
                              },
                            )),
                  );
                },
              ),
              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildIconTextItem(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: icon,
        ),
        const SizedBox(
          width: 24,
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.displaySmall,
              )
            ],
          ),
        ),
      ],
    );
  }
}
