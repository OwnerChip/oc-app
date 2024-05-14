import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class OnboardingScreenWithStepsArguments {
  final String title;
  final List<Widget Function(BuildContext context)> stepBuilders;
  final Widget Function(BuildContext context) completedButtonBuilder;

  const OnboardingScreenWithStepsArguments({
    required this.title,
    required this.stepBuilders,
    required this.completedButtonBuilder,
  });
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
              style: Theme.of(context).textTheme.displayMedium,
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
