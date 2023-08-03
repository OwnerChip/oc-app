import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/providers.services.dart';
import 'package:ownerchip_whitelabel/services/walletconnect.services.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/credentials.dart';
import '../../utils/localization.helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

Future<void> authPopupBuilder(
    BuildContext context, WidgetRef ref, Web3App wc) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          //border radius
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 10),
            child: Text(
              'Authenticate your wallet plz.',
              textAlign: TextAlign.center,
            ),
          ),
          titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomRoundedButton(
                  text: 'Authenticate',
                  onPressed: () => onTapAuth('insert_session_id', ref)),
            ],
          ));
    },
  );
}

Future<void> onTapAuth(String sessionId, WidgetRef ref) async {
  Web3App? wc = ref.read(wcProvider);
  EthereumAddress userWalletAddress = ref.read(userAddressProvider);
  SessionData? session = ref.read(wcSessionProvider);
  WalletType? walletType = ref.read(walletTypeProvider);

  sendPersonalSignRequest(
      'insert_session_id', userWalletAddress, wc!, session!, walletType!);
}
