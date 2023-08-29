//import packages

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:web3dart/credentials.dart';

class AdminInitCard extends ConsumerStatefulWidget {
  const AdminInitCard({Key? key}) : super(key: key);

  static const routeName = '/adminInitCard';

  @override
  _AdminInitCard createState() => _AdminInitCard();
}

class _AdminInitCard extends ConsumerState<AdminInitCard> {
  EthereumAddress? chipAddress1;
  EthereumAddress? chipAddress2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        text: 'Init second card slot',
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        children: [
          Column(
            children: [],
          ),
          CustomRoundedButton(
            text: 'Init second card slot',
            onPressed: () {
              ;
            },
          )
        ],
      ),
    );
  }
}
