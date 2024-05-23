import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

//stateless riverpod widget ConsumerWidget
class CryptoCurrencyDropdown extends ConsumerWidget {
  const CryptoCurrencyDropdown(
      {super.key,
      required this.setCurrency,
      required this.allDropDownItems,
      required this.selectedCurrency});

  final Function setCurrency;
  final String selectedCurrency;
  final List<String> allDropDownItems;

  _buildDropdown(data, ref, String selectString, Function setCurrency,
      String selectedCurrency) {
    return DropdownButton<String>(
        focusColor: Colors.red,
        icon: Icon(Icons.arrow_drop_down),
        iconSize: 24,
        underline: Container(),
        isDense: true,
        dropdownColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        style: TextStyle(
            color: CustomColors(dotenv.get('APP_ID')).chainDropdownTextColor),
        value: selectedCurrency,
        onChanged: (value) {
          setCurrency(value);
        },
        items: data.map<DropdownMenuItem<String>>((String currency) {
          return DropdownMenuItem(value: currency, child: Text(currency));
        }).toList());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildDropdown(
        allDropDownItems,
        ref,
        context.loc.pleaseSelect,
        setCurrency,
        selectedCurrency); //TODO: make the currencies flexible depending on the chain the token is on
  }
}
