//import packages

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:sentry/sentry.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:pinput/pinput.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({Key? key}) : super(key: key);

  static const routeName = '/pinInput';

  @override
  _PinScreen createState() => _PinScreen();
}

class _PinScreen extends ConsumerState<PinScreen> {
  String text = 'Set up PIN for OwnerCard';
  String pin = '';

  Future<void> onSavePress(BuildContext context) async {
    setPinOnCard(context, pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: 'Enter PIN',
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.credit_card,
            size: 60,
            color: CustomColors(dotenv.get('APP_ID')).primaryColor,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: Text(
              textAlign: TextAlign.center,
              text,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 25),
          Pinput(
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            obscureText: true,
            onCompleted: (pin) => setState(() {
              this.pin = pin;
            }),
          ),
          const SizedBox(height: 40),
          CustomRoundedButton(
              text: 'Save',
              onPressed: () {
                onSavePress(context);
              })
        ],
      ),
    );
  }
}

PinTheme defaultPinTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: TextStyle(
      fontSize: 20,
      color: Color.fromRGBO(30, 60, 87, 1),
      fontWeight: FontWeight.w600),
  decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Color.fromRGBO(234, 239, 243, 1)),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: CustomColors(dotenv.get('APP_ID')).secondaryShadowColor,
          offset: const Offset(1, 3),
          blurRadius: 3,
        ),
      ]),
);

PinTheme focusedPinTheme = defaultPinTheme.copyDecorationWith(
  border: Border.all(color: Color.fromRGBO(77, 121, 255, 1)),
  borderRadius: BorderRadius.circular(12),
);

PinTheme submittedPinTheme = defaultPinTheme.copyWith(
  decoration: defaultPinTheme.decoration!.copyWith(
    color: Color.fromRGBO(234, 239, 243, 1),
  ),
);
