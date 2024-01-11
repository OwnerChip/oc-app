//import packages

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/purchasesData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:country_picker/country_picker.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';

class EnterShippingAddressScreen extends ConsumerStatefulWidget {
  const EnterShippingAddressScreen({Key? key}) : super(key: key);

  static const routeName = '/enterShippingAddress';

  @override
  _OfferOnMPScreen createState() => _OfferOnMPScreen();
}

class _OfferOnMPScreen extends ConsumerState<EnterShippingAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sellerPayoutInputController = TextEditingController();

  bool isLoading = false;
  //name
  String firstName = '';
  String lastName = '';

  //address
  String streetAddress = '';
  String streetAddress1 = '';
  String city = '';
  String zip = '';
  String state = '';
  String country = '';
  String countryCode = '';
  String company = '';

  //contact
  String email = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
  }

  Future<void> sendShippingData() async {
    ShippingInfo shippingInfo = ShippingInfo(
        firstName: firstName,
        lastName: lastName,
        streetAddress: streetAddress,
        streetAddress1: streetAddress1,
        city: city,
        postalCode: zip,
        stateOrProvince: state,
        countryCode: countryCode,
        companyName: company,
        email: email,
        phoneNumber: phone);

    try {
      List<Purchase> unredeemedVoucherNfts =
          await ref.read(unredeemedVoucherNftsProvider.future);

      if (unredeemedVoucherNfts.isNotEmpty) {
        await postShippingInfoToBackend(unredeemedVoucherNfts[0], shippingInfo);

        Navigator.pop(context);
        Navigator.pop(context);

        // ignore: use_build_context_synchronously
        showCustomPopup(
            context,
            'Shipping data successfully sent.',
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  'You will receive further details via email.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                CustomRoundedButton(
                    text: context.loc.done,
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ],
            ),
            icon: Icon(Icons.celebration,
                size: 90,
                color: CustomColors(dotenv.get('APP_ID')).accentColor),
            titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize:
                    CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
                color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                fontWeight:
                    CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
            titlePadding: const EdgeInsets.all(0));
      }
    } catch (e) {
      print(e);
      await Sentry.captureException(e);
    }
  }

  @override
  void dispose() {
    _sellerPayoutInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameInputFields = [
      InputFieldModel(
          placeholder: 'First Name',
          keyboardType: TextInputType.name,
          setStateCallback: (value) {
            setState(() {
              firstName = value;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return null;
            } else {
              return 'Please enter last name.';
            }
          }),
      InputFieldModel(
          placeholder: 'Last Name',
          keyboardType: TextInputType.name,
          setStateCallback: (value) {
            setState(() {
              lastName = value;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return null;
            } else {
              return 'Please enter last name.';
            }
          }),
    ];

    final contactInputFields = [
      InputFieldModel(
          placeholder: 'Email',
          keyboardType: TextInputType.emailAddress,
          setStateCallback: (value) {
            setState(() {
              email = value;
            });
          },
          validator: (value) {
            bool isEmail =
                RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!);
            print('isemail: $isEmail');
            if (isEmail) {
              return null;
            } else {
              return context.loc.pleaseEnterValidEmailAddress;
            }
          }),
      InputFieldModel(
          placeholder: 'Phone (optional)',
          keyboardType: TextInputType.phone,
          setStateCallback: (value) {
            setState(() {
              phone = value;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              bool isTelNr = RegExp(
                      r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$')
                  .hasMatch(value);
              if (!isTelNr) {
                return context.loc.pleaseEnterValidTel;
              }
              return null;
            }
          }),
    ];

    final addressInputFields = [
      InputFieldModel(
          placeholder: 'Company (optional)',
          keyboardType: TextInputType.streetAddress,
          setStateCallback: (value) {
            setState(() {
              company = value;
            });
          },
          validator: (value) {}),
      InputFieldModel(
          placeholder: 'Street Address',
          keyboardType: TextInputType.streetAddress,
          setStateCallback: (value) {
            setState(() {
              streetAddress = value;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return null;
            } else {
              return 'Please enter street address.';
            }
          }),
      InputFieldModel(
          placeholder: 'Street Address 1 (optional)',
          keyboardType: TextInputType.streetAddress,
          setStateCallback: (value) {
            setState(() {
              streetAddress1 = value;
            });
          },
          validator: (value) {}),
      InputFieldModel(
          placeholder: 'City',
          keyboardType: TextInputType.streetAddress,
          setStateCallback: (value) {
            setState(() {
              city = value;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return null;
            } else {
              return 'Please enter city.';
            }
          }),
      InputFieldModel(
          placeholder: 'Zip',
          keyboardType: TextInputType.number,
          setStateCallback: (value) {
            setState(() {
              zip = value;
            });
          },
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return null;
            } else {
              return 'Please enter zip.';
            }
          }),
      InputFieldModel(
          placeholder: 'State/Province (optional)',
          keyboardType: TextInputType.streetAddress,
          setStateCallback: (value) {
            setState(() {
              state = value;
            });
          },
          validator: (value) {}),
    ];

    return Scaffold(
      key: ScaffoldKey.getScaffoldKey('EnterShippingAddressScreen'),
      appBar: CustomAppBar(
        text: 'Shipping address',
        showBackButton: true,
      ),
      body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ScreenBodyLayout(
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
                            Text('Name',
                                style:
                                    Theme.of(context).textTheme.headlineSmall!),
                            const SizedBox(
                              height: 5,
                            ),
                            ...nameInputFields.map((inputField) {
                              return Column(children: [
                                TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(
                                      context, inputField.placeholder!,
                                      fillColor: CustomColors(
                                              dotenv.get('APP_ID').toString())
                                          .cardColor),
                                  keyboardType: inputField.keyboardType,
                                  obscureText: false,
                                  onChanged: (value) {
                                    inputField.setStateCallback(value);
                                  },
                                  validator: (value) {
                                    return inputField.validator(value);
                                  },
                                ),
                                const SizedBox(height: 10)
                              ]);
                            }).toList(),
                          ]),
                      const SizedBox(
                        height: 40,
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address',
                                style:
                                    Theme.of(context).textTheme.headlineSmall!),
                            const SizedBox(
                              height: 5,
                            ),
                            ...addressInputFields.map((inputField) {
                              return Column(children: [
                                TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(
                                      context, inputField.placeholder!,
                                      fillColor: CustomColors(
                                              dotenv.get('APP_ID').toString())
                                          .cardColor),
                                  keyboardType: inputField.keyboardType,
                                  obscureText: false,
                                  onChanged: (value) {
                                    inputField.setStateCallback(value);
                                  },
                                  validator: (value) {
                                    return inputField.validator(value);
                                  },
                                ),
                                const SizedBox(height: 10)
                              ]);
                            }).toList(),
                            const SizedBox(height: 10),
                            TextFormField(
                              onTap: () {
                                print('test');
                                showCountryPicker(
                                  context: context,
                                  onSelect: (Country country) {
                                    setState(() {
                                      this.country =
                                          country.displayNameNoCountryCode;
                                      countryCode = country.countryCode;
                                    });
                                    print(
                                        'Select country: ${country.displayName}');
                                  },
                                  countryListTheme: CountryListThemeData(
                                    flagSize: 25,
                                    backgroundColor:
                                        CustomColors(dotenv.get('APP_ID'))
                                            .secondaryColor,
                                    textStyle: TextStyle(
                                        fontSize: 16,
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .primaryColor),
                                    searchTextStyle: TextStyle(
                                        fontSize: 16,
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .primaryColor),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20.0),
                                      topRight: Radius.circular(20.0),
                                    ),
                                    //Optional. Styles the search field.
                                    inputDecoration: InputDecoration(
                                      //TODO: localize text
                                      labelText: 'Search',
                                      labelStyle: TextStyle(
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .primaryColor),
                                      hintText: 'Start typing to search',
                                      hintStyle: TextStyle(
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .primaryColor),
                                      prefixIcon: Icon(Icons.search,
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .primaryColor),
                                      // border: OutlineInputBorder(
                                      //   borderSide: BorderSide(
                                      //     color:
                                      //         CustomColors(dotenv.get('APP_ID'))
                                      //             .primaryColor,
                                      //   ),
                                      // ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              controller: TextEditingController(text: country),
                              readOnly: true,
                              style: Theme.of(context).textTheme.bodyMedium,
                              cursorColor:
                                  CustomColors(dotenv.get('APP_ID').toString())
                                      .accentColor,
                              decoration: customInputDecoration(
                                  context, 'Country',
                                  fillColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .cardColor),
                              obscureText: false,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  return null;
                                } else {
                                  return 'Please enter country.';
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
                            Text('Contact',
                                style:
                                    Theme.of(context).textTheme.headlineSmall!),
                            const SizedBox(
                              height: 5,
                            ),
                            ...contactInputFields.map((inputField) {
                              return Column(children: [
                                TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(
                                      context, inputField.placeholder!,
                                      fillColor: CustomColors(
                                              dotenv.get('APP_ID').toString())
                                          .cardColor),
                                  keyboardType: inputField.keyboardType,
                                  obscureText: false,
                                  onChanged: (value) {
                                    inputField.setStateCallback(value);
                                  },
                                  validator: (value) {
                                    return inputField.validator(value);
                                  },
                                ),
                                const SizedBox(height: 10)
                              ]);
                            }).toList(),
                          ]),
                      const SizedBox(
                        height: 40,
                      ),
                      CustomRoundedButton(
                          text: 'Send shipping data',
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await sendShippingData();
                            }
                          }),
                      const SizedBox(height: 10),
                    ],
                  )),
            ],
          )),
    );
  }
}
