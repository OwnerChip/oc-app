// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import '../utils/localization.helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//web3 imports
import 'package:web3dart/crypto.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../services/web3.services.dart';

//nfc imports
import 'package:nfc_manager/nfc_manager.dart';
import 'package:ownerchip_whitelabel/services/nfc.service.dart';
import '../services/signature.service.dart';

//local imports
import 'UserScanResultsScreen.dart';
import 'MetadataInputScreen.dart';
import 'ChipAlreadyInitializedScreen.dart';
import '../utils/navigation.arguments.dart';
import '../utils/utils.dart';
import '../widgets/ui/CustomAppBar.dart';
import '../widgets/ui/ScanningIndicator.dart';
import '../widgets/ui/returnSnackBarWidget.dart';
import '../widgets/ui/CustomRoundedButton.dart';
import '../widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/utils/constants.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  static const routeName = '/scanning';

  @override
  _ScanningScreen createState() => _ScanningScreen();
}

//flutter stateless widget
class _ScanningScreen extends ConsumerState<ScanningScreen> {
  // @override
  // void initState() {
  //   super.initState();
  //   initScanning(ref);
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initScanning(ref);
  }

  void initScanning(WidgetRef ref) async {
    Uint8List hashedMsg;
    MsgSignature signature;
    int randomNumber = makeRandomInt();
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;

    //start NFC scan
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      try {
        var nfc = NFCPlatform(tag);

        //check if iso7816 or isodep is available and exit if not
        await nfcPlatformCheck(context, nfc);

        //initialize chip
        List result = await initializeChip(nfc);
        EthereumAddress chipEthereumAddress = result[0];
        BigInt chipTokenId = result[1];

        ref
            .read(chipInfoProvider.notifier)
            .setChipEthereumAddress(chipEthereumAddress);
        ref.read(chipInfoProvider.notifier).setTokenId(chipTokenId);

        List config = await ref.watch(findTokenProvider(chipTokenId).future);

        //vibrate phone
        await vibrateNTimes(3);

        //verify signature
        List verifyResult = await verifySignatureAuthenticity(
            nfc, randomNumber, chipEthereumAddress, chipTokenId);
        hashedMsg = verifyResult[0];
        signature = verifyResult[1];

        if (config[1] == '0x0000000000000000000000000000000000000000') {
          //TOKEN DOES NOT EXIST
          NfcManager.instance.stopSession();

          if (navArgs.nextRoute == UserScanResultsScreen.routeName) {
            Navigator.pushReplacementNamed(
              context,
              UserScanResultsScreen.routeName,
            );
          } else {
            Navigator.pushReplacementNamed(context, MetadataScreen.routeName,
                arguments: MetadataScreenArguments(hashedMsg, signature));
          }
        } else {
          //TOKEN EXISTS
          try {
            //verify token authenticity via smart contract
            bool tokenIsAuthentic = await verifyTokenAuthenticity(
                getRPCUrlFromChainId(config[0]),
                config[1],
                chipEthereumAddress,
                hashedMsg,
                signature);

            NfcManager.instance.stopSession();
            if (navArgs.nextRoute == UserScanResultsScreen.routeName) {
              Navigator.pushReplacementNamed(
                  context, UserScanResultsScreen.routeName);
            } else {
              Navigator.pushReplacementNamed(
                  context, ChipAlreadyInitializedScreen.routeName,
                  arguments: ChipAlreadyInitializedScreenArguments(
                      hashedMsg, signature));
            }
          } catch (e) {
            //TOKEN IS NOT AUTHENTIC
            rethrow;
          }
        }
      } catch (e) {
        //error reading chip
        NfcManager.instance.stopSession();
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.errorHeadingSnackBar, context.loc.nfcError, 'error'),
        );
        //delay for 1 second
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      }
    });
  }

  void cancelScan() {
    NfcManager.instance.stopSession();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    WalletConnect wc = ref.watch(walletConnectProvider);
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          connectedWalletAddress: wc.session.accounts.isEmpty == true
              ? null
              : wc.session.accounts[0].toLowerCase(),
          showBackButton: false,
        ),
        body: ScreenBodyLayout(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          withScrollView: false,
          children: [
            (navArgs.nextRoute == MetadataScreen.routeName)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.loc.initializeChip,
                          style: Theme.of(context).textTheme.headline2),
                      RichText(
                        text: TextSpan(
                            text: 'Step 1/',
                            style: Theme.of(context)
                                .textTheme
                                .headline6!
                                .copyWith(fontSize: 18),
                            children: [
                              TextSpan(
                                  text: '2',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headline5!
                                      .copyWith(fontSize: 18))
                            ]),
                      )
                    ],
                  )
                : Text(context.loc.scanning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline2),
            Column(
              children: [
                SvgPicture.asset(
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_light_blue.svg',
                  width: 70.0,
                ),
                const SizedBox(height: 20),
                const ScanningIndicator(),
                const SizedBox(height: 20),
                SvgPicture.asset(
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/phone.svg',
                  width: 70.0,
                ),
                const SizedBox(height: 30),
                Text(context.loc.scanHint,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyText1!
                    // .copyWith(fontWeight: FontWeight.w400),
                    ),
              ],
            ),
            CustomRoundedButton(
              text: context.loc.cancel,
              onPressed: () => cancelScan(),
            )
          ],
        ));
  }
}
