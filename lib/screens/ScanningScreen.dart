// ignore_for_file: use_build_context_synchronously

//import packages
import 'package:flutter/material.dart';
import 'package:web3dart/credentials.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:web3dart/crypto.dart';
import 'dart:io' show Platform;
import 'package:sentry/sentry.dart';

//import services
import 'package:ownerchip_whitelabel/services/nfc.service.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/signature.service.dart';
import 'package:ownerchip_whitelabel/services/providers.service.dart';

//import screens
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:ownerchip_whitelabel/screens/MetadataInputScreen.dart';
import 'package:ownerchip_whitelabel/screens/ChainSelectorScreen.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/ScanningIndicator.dart';
import 'package:ownerchip_whitelabel/widgets/ui/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/navigation.arguments.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  static const routeName = '/scanning';

  @override
  _ScanningScreen createState() => _ScanningScreen();
}

class _ScanningScreen extends ConsumerState<ScanningScreen> {
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
    final scanProcess = Sentry.startTransaction('initScanning()', 'task');
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      sendAnalyticsTrace("$randomNumber", "", "SCAN_STARTED");
      try {
        var nfc = NFCPlatform(tag);

        //check if iso7816 or isodep is available and exit if not
        await nfcPlatformCheck(context, randomNumber, nfc);

        //initialize chip (including NDEF tag if existing)
        bool initProcess = navArgs.nextRoute == ChainSelectorScreen.routeName;
        if (initProcess) {
          sendAnalyticsTrace("$randomNumber", "", "INITIALIZE_NDEF_START");
        }
        List result = await initializeChip(nfc, initProcess, randomNumber);
        EthereumAddress chipEthereumAddress = result[0];
        String chipWalletAddress = chipEthereumAddress.toString();
        BigInt chipTokenId = result[1];
        bool ndefTagInitialized = result[2];
        if (ndefTagInitialized) {
          sendAnalyticsTrace(
              "$randomNumber", chipWalletAddress, "CHIP_INITIALIZED");
        }

        //set chip info data in provider
        ref
            .read(chipInfoProvider.notifier)
            .setChipEthereumAddress(chipEthereumAddress);
        ref.read(chipInfoProvider.notifier).setTokenId(chipTokenId);
        ref.read(chipInfoProvider.notifier).setChipToInitialized();

        TokenInfoObject config =
            await ref.watch(findTokenProvider(chipTokenId).future);

        //verify signature
        List verificationResult = await verifySignatureAuthenticity(nfc,
            randomNumber, chipEthereumAddress, chipTokenId, ndefTagInitialized);
        hashedMsg = verificationResult[0];
        signature = verificationResult[1];
        ref.read(signatureDataProvider.notifier).setSignatureData(
            SignatureData(hashedMsg: hashedMsg, signature: signature));

        //stop NFC session if iOS, Android nfc Session is stopped later to block NDEF read for longer
        if (Platform.isIOS) {
          NfcManager.instance.stopSession();
        }

        if (config.collectionId == zeroAddress) {
          sendAnalyticsTrace("$randomNumber", "", "SCAN_RESULT_NEGATIVE",
              tags: {"chipWallet": chipWalletAddress});
          //TOKEN DOES NOT EXIST
          if (navArgs.nextRoute == UserScanResultsScreen.routeName) {
            Navigator.pushReplacementNamed(
              context,
              UserScanResultsScreen.routeName,
            );
          } else {
            Navigator.pushReplacementNamed(
                context, ChainSelectorScreen.routeName,
                arguments:
                    MetadataInputScreenArguments(randomNumber, 0, zeroAddress));
          }
        } else {
          //TOKEN EXISTS
          try {
            //verify token authenticity via smart contract
            bool tokenIsAuthentic = await verifyTokenAuthenticity(
                getRPCUrlFromChainId(config.chainId),
                config.collectionId,
                chipEthereumAddress,
                hashedMsg,
                signature);

            scanProcess.finish();
            sendAnalyticsTrace("$randomNumber", "", "SCAN_RESULT_POSITIVE",
                tags: {"chipWallet": chipWalletAddress});
            Navigator.pushReplacementNamed(
                context, UserScanResultsScreen.routeName);
          } catch (e) {
            //TOKEN IS NOT AUTHENTIC
            rethrow;
          }
        }
        //iOS NFC session is stopped earlier in code; Android NFC session is stopped here after 3 seconds to block NDEF read/popup
        await Future.delayed(const Duration(seconds: 3));
        NfcManager.instance.stopSession();
      } catch (e, stackTrace) {
        // send Error to analytics
        sendAnalyticsTrace("$randomNumber", "$e", "SCAN_ERROR");
        print(e);
        scanProcess.throwable = e;
        scanProcess.status = const SpanStatus.deadlineExceeded();
        scanProcess.finish();
        await Sentry.captureException(
          e,
          stackTrace: stackTrace,
        );
        //error reading chip
        NfcManager.instance.stopSession();
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
              context.loc.errorHeadingSnackBar, context.loc.nfcError, 'error'),
        );
        //delay for 1 second
        await Future.delayed(const Duration(seconds: 1));
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
    //TODO: check
    final wc = ref.watch(wcProvider);
    final navArgs =
        ModalRoute.of(context)!.settings.arguments as ScanningScreenArguments;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const CustomAppBar(
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
                          style: Theme.of(context).textTheme.displayMedium),
                      RichText(
                        text: TextSpan(
                            text: 'Step 1/',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(fontSize: 18),
                            children: [
                              TextSpan(
                                  text: '2',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!
                                      .copyWith(fontSize: 18))
                            ]),
                      )
                    ],
                  )
                : Text(context.loc.scanning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium),
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
                    style: Theme.of(context).textTheme.bodyLarge!
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
