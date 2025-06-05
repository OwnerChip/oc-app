import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class CreationCancelPopup extends StatelessWidget {
  final String description;
  final String yes;
  final String cancel;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(description),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              width: double.maxFinite,
              child: CustomRoundedButton(
                  text: yes,
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  }),
            ),
            const SizedBox(
              height: 8,
            ),
            SizedBox(
              width: double.maxFinite,
              child: CustomOutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  buttonText: cancel),
            )
          ],
        ),
      ),
    );
  }

  const CreationCancelPopup({
    required this.description,
    required this.yes,
    required this.cancel,
    super.key,
  });
}
