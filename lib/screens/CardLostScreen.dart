//import packages

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';

class CardLostScreen extends ConsumerStatefulWidget {
  const CardLostScreen({Key? key}) : super(key: key);

  static const routeName = '/cardLost';

  @override
  _CardLostScreen createState() => _CardLostScreen();
}

class _CardLostScreen extends ConsumerState<CardLostScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String name = '';
  String telNr = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: context.loc.cardLost,
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: true,
        children: [
          Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(context.loc.toRequestNewCard,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 40),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: TextFormField(
                      style: Theme.of(context).textTheme.bodyMedium,
                      cursorColor: CustomColors(dotenv.get('APP_ID').toString())
                          .accentColor,
                      decoration: customInputDecoration(context, 'Name',
                          fillColor:
                              CustomColors(dotenv.get('APP_ID')).cardColor),
                      keyboardType: TextInputType.text,
                      obscureText: false,
                      onChanged: (value) {
                        setState(() {
                          name = value;
                        });
                      },
                      validator: (value) {
                        //validate if value is email
                        if (value != null && value.isNotEmpty) {
                          return null;
                        } else {
                          return context.loc.pleaseEnterValidName;
                        }
                      },
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: TextFormField(
                      style: Theme.of(context).textTheme.bodyMedium,
                      cursorColor: CustomColors(dotenv.get('APP_ID').toString())
                          .accentColor,
                      decoration: customInputDecoration(
                          context, context.loc.emailAddress,
                          fillColor:
                              CustomColors(dotenv.get('APP_ID')).cardColor),

                      // InputDecoration(
                      //   labelText: context.loc.emailAddress,
                      //   labelStyle: Theme.of(context).textTheme.bodyMedium,
                      //   enabledBorder: OutlineInputBorder(
                      //     borderRadius: BorderRadius.circular(10),
                      //     borderSide: BorderSide(
                      //         color:
                      //             CustomColors(dotenv.get('APP_ID').toString())
                      //                 .primaryColor,
                      //         width: 2.0), // normal border color
                      //   ),
                      //   focusedBorder: OutlineInputBorder(
                      //     borderRadius: BorderRadius.circular(10),
                      //     borderSide: BorderSide(
                      //         color:
                      //             CustomColors(dotenv.get('APP_ID').toString())
                      //                 .primaryColor,
                      //         width: 2.0), // focused border color
                      //   ),
                      // ),
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
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: TextFormField(
                      style: Theme.of(context).textTheme.bodyMedium,
                      cursorColor: CustomColors(dotenv.get('APP_ID').toString())
                          .accentColor,
                      decoration: customInputDecoration(
                          context, context.loc.phoneNumber,
                          fillColor:
                              CustomColors(dotenv.get('APP_ID')).cardColor),
                      keyboardType: TextInputType.text,
                      obscureText: false,
                      onChanged: (value) {
                        setState(() {
                          telNr = value;
                        });
                      },
                      validator: (value) {
                        //validate if value is phone
                        bool isTelNr = RegExp(
                                r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$')
                            .hasMatch(value!);
                        print(isTelNr);
                        if (!isTelNr) {
                          return context.loc.pleaseEnterValidTel;
                        }
                        return null;
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
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
                              showCustomPopup(
                                  context,
                                  context.loc.pleaseScanItem,
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          context.loc.scanItemToTriggerCardLost,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                      const SizedBox(height: 15),
                                      CustomRoundedButton(
                                        text: 'Scan',
                                        onPressed: () async {
                                          bool success = await triggerCardLost(
                                              context, ref, email, name, telNr);
                                          Navigator.pop(context);
                                          if (success) {
                                            // ignore: use_build_context_synchronously
                                            showCustomPopup(
                                                context,
                                                context.loc.requestSent,
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                        textAlign:
                                                            TextAlign.center,
                                                        context.loc
                                                            .cardLostContacted,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium),
                                                    const SizedBox(height: 10),
                                                    CustomRoundedButton(
                                                        text: context.loc.done,
                                                        onPressed: () {
                                                          Navigator.pushNamed(
                                                              context,
                                                              HomeScreen
                                                                  .routeName);
                                                        })
                                                  ],
                                                ));
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(returnSnackBarWidget(
                                                    context.loc
                                                        .errorHeadingSnackBar,
                                                    context.loc
                                                        .pleaseTryAgainLater,
                                                    'error'));
                                          }
                                        },
                                      )
                                    ],
                                  ));
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
