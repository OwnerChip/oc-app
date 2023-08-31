//import packages

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/navigationArguments.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SuccessPinSetup.dart';
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
  String title = 'Set up PIN for OwnerCard';
  String buttonText = 'Save';

  String pin = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as PinScreenArguments;

    if (navArgs.activeFeature == PinScreenActiveFeature.setPin) {
      setState(() {
        title = context.loc.setUpPin;
        buttonText = context.loc.save;
      });
    } else if (navArgs.activeFeature == PinScreenActiveFeature.verifyPinAuth) {
      setState(() {
        title = context.loc.enterPinToAuth;
        buttonText = context.loc.connectOwnerCard;
      });
    } else if (navArgs.activeFeature == PinScreenActiveFeature.verifyPinTx) {
      setState(() {
        title = context.loc.enterPinToConfirmTx;
        buttonText = context.loc.confirmTx;
      });
    } else {
      String errorMsg = 'Invalid PinScreenActiveFeature Navigation Argument';
      Sentry.captureException(errorMsg);
      throw Exception(errorMsg);
    }
  }

  Future<void> onSavePress(BuildContext context) async {
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as PinScreenArguments;

    try {
      var value = await navArgs.callback(pin);
      if (navArgs.activeFeature == PinScreenActiveFeature.verifyPinTx) {
        Navigator.pop(context, value);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            'An error occurred. Please try again later.', 'error'),
      );
      print(e);
      Sentry.captureException(e);
    }
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
              title,
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
              text: context.loc.save,
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
