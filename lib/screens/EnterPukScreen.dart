//import packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class EnterPukScreen extends ConsumerStatefulWidget {
  const EnterPukScreen({Key? key}) : super(key: key);

  static const routeName = '/pukInput';

  @override
  _EnterPukScreen createState() => _EnterPukScreen();
}

class _EnterPukScreen extends ConsumerState<EnterPukScreen> {
  String puk = '';

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
                  decoration: InputDecoration(
                    labelText: 'PUK',
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
            ],
          ),
          SizedBox(
            height: 20,
          ),
          CustomRoundedButton(
            text: 'Reset PIN',
            onPressed: () {
              resetPinOnCard(ref, context, puk);
            },
          )
        ],
      ),
    );
  }
}
