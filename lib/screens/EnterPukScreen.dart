//import packages

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SuccessPinSetup.dart';

class EnterPukScreen extends ConsumerStatefulWidget {
  const EnterPukScreen({Key? key}) : super(key: key);

  static const routeName = '/pukInput';

  @override
  _EnterPukScreen createState() => _EnterPukScreen();
}

class _EnterPukScreen extends ConsumerState<EnterPukScreen> {
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
                child: TextFormField(
                  style: Theme.of(context).textTheme.bodyMedium,
                  cursorColor:
                      CustomColors(dotenv.get('APP_ID').toString()).accentColor,
                  decoration: InputDecoration(
                    labelText: context.loc.enterPUK,
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: CustomColors(dotenv.get('APP_ID').toString())
                              .primaryColor,
                          width: 2.0), // normal border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: CustomColors(dotenv.get('APP_ID').toString())
                              .primaryColor,
                          width: 2.0), // focused border color
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  obscureText: false,
                  onChanged: (value) {
                    setState(() {
                      puk = value;
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                margin: EdgeInsets.only(top: 20),
                child: TextFormField(
                  style: Theme.of(context).textTheme.bodyMedium,
                  cursorColor:
                      CustomColors(dotenv.get('APP_ID').toString()).accentColor,
                  decoration: InputDecoration(
                    labelText: context.loc.enterFourDigitPin,
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: CustomColors(dotenv.get('APP_ID').toString())
                              .primaryColor,
                          width: 2.0), // normal border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: CustomColors(dotenv.get('APP_ID').toString())
                              .primaryColor,
                          width: 2.0), // focused border color
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: false,
                  onChanged: (value) {
                    setState(() {
                      pin = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          CustomRoundedButton(
            text: 'Reset PIN',
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
