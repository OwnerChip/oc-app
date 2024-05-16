import 'package:flutter/material.dart';

class OnboardingScreenUserStep extends StatelessWidget {
  const OnboardingScreenUserStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.footer,
  });

  final Widget Function(BuildContext context) content;
  final String title;
  final String subtitle;

  final Widget Function(BuildContext context)? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        content(context),
        const SizedBox(
          height: 24,
        ),
        Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        Center(
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(
            height: 24,
          ),
          footer!(context),
        ],
      ],
    );
  }
}
