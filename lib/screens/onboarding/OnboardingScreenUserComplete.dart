import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/screens/onboarding/OnboardingScreenWithSteps.dart';
import 'package:ownerchip_whitelabel/services/providers/onboardingProvider.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCheckBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreenUserComplete extends ConsumerWidget {
  const OnboardingScreenUserComplete({super.key});

  static const routeName = '/onboardingUserComplete';

  bool get _showCreatorTutorial => dotenv.env['APP_ID'] == 'ownerchip';
  // bool get _showCreatorTutorial => false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);

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
            if (_showCreatorTutorial) ...[
              const Spacer(
                flex: 4,
              ),
              Text(
                context.loc.onboardingUserCompleteCreatorPageTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                context.loc.onboardingUserCompleteCreatorPageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
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
                      arguments:
                          OnboardingScreenWithStepsArguments.creatorTutorial(
                              context),
                    );
                  }),
            ],
            const Spacer(
              flex: 3,
            ),
            Icon(
              Icons.celebration_outlined,
              size: 128,
              color: CustomColors(dotenv.get('APP_ID')).accentColor,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              context.loc.onboardingUserCompleteTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              context.loc.onboardingUserCompleteSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (_showCreatorTutorial)
              const SizedBox(
                height: 24,
              )
            else
              const Spacer(
                flex: 6,
              ),
            onboarding.maybeWhen(data: (data) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CustomCheckBox(
                    value: data.showTutorialNextTime,
                    onChanged: (value) {
                      ref
                          .read(onboardingProvider.notifier)
                          .updateShowTutorialNextTime(value);
                    },
                  ),
                  Text(
                    context.loc.onboardingCheckboxShowAgainTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }, orElse: () {
              return const SizedBox();
            }),
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
