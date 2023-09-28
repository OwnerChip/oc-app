import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:web3dart/web3dart.dart';

class AuthenticityBoxContent extends StatelessWidget {
  const AuthenticityBoxContent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    //Text where one word is tappable (detects gestures)
    return Row(
      children: [
        Text(
          'Digital twin by ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          height: 10,
        ),
        GestureDetector(
          onTap: () {
            showCustomPopup(
                context, 'This is title', Text('Item verified by XZY'));
          },
          child: Text(
            'tap me',
            style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorLight,
                ),
          ),
        ),
      ],
    );
  }
}
