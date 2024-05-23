//import packages

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/StyledTextInputBox.dart';

class EnterPukScreen extends ConsumerStatefulWidget {
  const EnterPukScreen({Key? key}) : super(key: key);

  static const routeName = '/pukInput';

  @override
  _EnterPukScreen createState() => _EnterPukScreen();
}

class _EnterPukScreen extends ConsumerState<EnterPukScreen> {
  final _pukController = TextEditingController();
  final _pinController = TextEditingController();
  String puk = '';
  String pin = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: context.loc.enterPuk,
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        children: [
          Column(
            children: [
              Container(
                  margin: EdgeInsets.only(top: 20),
                  child: StyledTextInputBox(
                    controller: _pukController,
                    fillColor: CustomColors(dotenv.get('APP_ID')).cardColor,
                    setText: (input) {
                      setState(() {
                        puk = input;
                      });
                    },
                    hintText: context.loc.enterPUK,
                  )),
              const SizedBox(
                height: 30,
              ),
              Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: StyledTextInputBox(
                    controller: _pinController,
                    fillColor: CustomColors(dotenv.get('APP_ID')).cardColor,
                    setText: (input) {
                      setState(() {
                        pin = input;
                      });
                    },
                    hintText: context.loc.enterFourDigitPin,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                  )),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          CustomRoundedButton(
            text: context.loc.resetPIN,
            onPressed: () async {
              FocusScope.of(context).unfocus();
              String? newPuk = await resetPinOnCard(context, ref, puk, pin);
              if (newPuk == null) {
                throw Exception("Error setting pin");
              }
              showCustomPopup(context, context.loc.pinResetSuccess,
                  PukDisplay(puk: newPuk));
            },
          )
        ],
      ),
    );
  }
}
