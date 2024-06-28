import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenWithSteps.dart';
import 'package:ownerchip_whitelabel/services/providers/onboardingProvider.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                      height: 24,
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
                      height: 24,
                    ),
                    _buildIconTextItem(
                      context,
                      icon: Icon(
                        Icons.star_outline_outlined,
                        size: 48,
                        color:
                            CustomColors(dotenv.get('APP_ID')).headline2Color,
                      ),
                      title:
                          context.loc.onboardingFeatureDigitalExperiencesTitle,
                      subtitle: context
                          .loc.onboardingFeatureDigitalExperiencesSubtitle,
                    ),
                    const SizedBox(
                      height: 24,
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
                  ],
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              CustomRoundedButton(
                text: context.loc.onboardingStartButton,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    OnboardingScreenWithSteps.routeName,
                    arguments: OnboardingScreenWithStepsArguments.userTutorial(
                        context),
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

  Widget _buildIconTextItem(
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
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            ],
          ),
        ),
      ],
    );
  }
}
