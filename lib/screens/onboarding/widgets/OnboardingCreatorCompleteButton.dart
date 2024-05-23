import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/providers/onboardingProvider.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCheckBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class OnboardingCreatorCompleteButton extends ConsumerWidget {
  const OnboardingCreatorCompleteButton({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final onboarding = ref.watch(onboardingProvider);

    return Column(
      children: [
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
        const SizedBox(
          height: 12,
        ),
        CustomRoundedButton(
            text: context.loc.onboardingCreatorCompleteButtonTitle,
            onPressed: () {
              Navigator.of(context).pop();
            }),
      ],
    );
  }
}
