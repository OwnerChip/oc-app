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
import 'package:ownerchip_whitelabel/widgets/ui/CryptoCurrencyDropdown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';

class OfferOnMPScreen extends ConsumerStatefulWidget {
  const OfferOnMPScreen({Key? key}) : super(key: key);

  static const routeName = '/offerOnMp';

  @override
  _OfferOnMPScreen createState() => _OfferOnMPScreen();
}

class _OfferOnMPScreen extends ConsumerState<OfferOnMPScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String walletAddress = '';
  double price = 0.00;
  String currencyDropdownValue =
      'MATIC'; //TODO: change this to the network the token is on
  bool raribleCheck = true;
  List allDropdownValues = [
    'MATIC',
    'EUR'
  ]; //TODO: change first element to the network the token is on

  //initState
  @override
  void initState() {
    super.initState();
    setState(() {
      allDropdownValues = [currencyDropdownValue, 'EUR'];
    });
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<Map> ethPriceEur =
        ref.watch(ethPriceProvider(allDropdownValues[0]));
    return Scaffold(
      appBar: CustomAppBar(
        text: 'Offer object',
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
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email address',
                            style: Theme.of(context).textTheme.headlineSmall!),
                        const SizedBox(
                          height: 5,
                        ),
                        TextFormField(
                          style: Theme.of(context).textTheme.bodyMedium,
                          cursorColor:
                              CustomColors(dotenv.get('APP_ID').toString())
                                  .accentColor,
                          decoration: customInputDecoration(
                              context, 'john@example.com',
                              fillColor:
                                  CustomColors(dotenv.get('APP_ID')).cardColor),
                          keyboardType: TextInputType.emailAddress,
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
                            if (isEmail) {
                              return null;
                            } else {
                              return context.loc.pleaseEnterValidEmailAddress;
                            }
                          },
                        ),
                      ]),
                  const SizedBox(
                    height: 40,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet address',
                            style: Theme.of(context).textTheme.headlineSmall!),
                        const SizedBox(
                          height: 5,
                        ),
                        TextFormField(
                          style: Theme.of(context).textTheme.bodyMedium,
                          cursorColor:
                              CustomColors(dotenv.get('APP_ID').toString())
                                  .accentColor,
                          decoration: customInputDecoration(
                              context, 'Enter wallet to receive the payment',
                              fillColor:
                                  CustomColors(dotenv.get('APP_ID')).cardColor),
                          keyboardType: TextInputType.text,
                          obscureText: false,
                          onChanged: (value) {
                            setState(() {
                              walletAddress = value;
                            });
                          },
                          validator: (value) {
                            //TODO: validate if this is wallet address
                            return null;
                          },
                        ),
                      ]),
                  const SizedBox(
                    height: 40,
                  ),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price',
                            style: Theme.of(context).textTheme.headlineSmall!),
                        const SizedBox(
                          height: 5,
                        ),
                        TextFormField(
                          style: Theme.of(context).textTheme.bodyMedium,
                          cursorColor:
                              CustomColors(dotenv.get('APP_ID').toString())
                                  .accentColor,
                          decoration: customInputDecoration(
                              suffix: CryptoCurrencyDropdown(
                                  setCurrency: (value) {
                                    setState(() {
                                      currencyDropdownValue = value;
                                    });
                                  },
                                  selectedCurrency: currencyDropdownValue),
                              context,
                              'Enter sale price for your object',
                              fillColor:
                                  CustomColors(dotenv.get('APP_ID')).cardColor),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          obscureText: false,
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                price = 0.0;
                              } else {
                                value = value.replaceAll(',', '.');
                                price = double.parse(value);
                              }
                            });
                          },
                          validator: (value) {
                            //TODO: validate if this is price
                          },
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          '${currencyDropdownValue == 'EUR' ? allDropdownValues[0] : 'EUR'} ${ethPriceEur.when(data: (data) {
                                if (currencyDropdownValue == 'EUR')
                                  return '${(price / data['EUR']).toStringAsFixed(2)}';
                                else
                                  return '${(price * data['EUR']).toStringAsFixed(2)}';
                              }, error: (e, s) => Container(), loading: () => 'Fetching price...')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      ]),
                  const SizedBox(
                    height: 40,
                  ),
                  //checkbox
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marketplace',
                          style: Theme.of(context).textTheme.headlineSmall!
                          // .copyWith(fontWeight: FontWeight.w700),
                          ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                              activeColor:
                                  CustomColors(dotenv.get('APP_ID').toString())
                                      .accentColor,
                              value: raribleCheck,
                              onChanged: (value) {
                                setState(() {
                                  raribleCheck = value!;
                                });
                              }),
                          Text(
                            'List on Rarible',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CustomRoundedButton(
                    text: 'Offer now',
                    onPressed: email.isEmpty ||
                            walletAddress.isEmpty ||
                            (price <= 0) ||
                            (raribleCheck) == false
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus();
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
