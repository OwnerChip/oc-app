//import packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/PukDisplay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SuccessPinSetup.dart';

class CardLostScreen extends ConsumerStatefulWidget {
  const CardLostScreen({Key? key}) : super(key: key);

  static const routeName = '/cardLost';

  @override
  _CardLostScreen createState() => _CardLostScreen();
}

class _CardLostScreen extends ConsumerState<CardLostScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: context.loc.cardLost,
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        children: [
          Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      obscureText: false,
                      onChanged: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      validator: (value) {
                        //validate if value is email
                        bool isEmail =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value!);
                        print('isemail: $isEmail');
                        if (isEmail) {
                          return null;
                        } else {
                          return context.loc.pleaseEnterValidEmailAddress;
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CustomRoundedButton(
                    text: context.loc.submit,
                    onPressed: email.isEmpty
                        ? null
                        : () async {
                            //dismiss keyboard
                            FocusScope.of(context).unfocus();
                            print(
                                'form key validate: ${_formKey.currentState!.validate()}');
                            if (_formKey.currentState!.validate()) {
                              bool success =
                                  await triggerCardLost(context, ref, email);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    returnSnackBarWidget(
                                        context.loc.successHeadingSnackbar,
                                        context.loc.cardLostContacted,
                                        'success'));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    returnSnackBarWidget(
                                        context.loc.errorHeadingSnackBar,
                                        'Please try again later.',
                                        'error'));
                              }
                            }
                          },
                  )
                ],
              )),
        ],
      ),
    );
  }
}
