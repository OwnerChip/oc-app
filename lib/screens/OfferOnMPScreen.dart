//import packages

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/screens/HomeScreen.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

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

  CancelableOperation? cancellableOperation;
  bool isLoading = false;
  String loadingText = '';
  String overlayContentType = 'loading'; //can be "traits" or "loading"
  String email = '';
  String sellerPayoutAddress = '';
  double price = 0.00;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  bool isRotating = true;
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

  Future<void> toggleLoading() async {
    setState(() {
      isLoading = !isLoading;
    });
  }

  Future<void> offerToken() async {
    final Web3App? wc = ref.read(wcProvider);
    final SignatureData signatureData = ref.read(chipSignatureDataProvider);
    final UserSession userSession = ref.read(userSessionProvider)!;
    final wcSession = ref.read(wcSessionProvider);
    final walletType = ref.read(walletTypeProvider);
    final ChipInfoModel chipInfo = ref.read(chipInfoProvider);
    final TokenInfoObject config =
        await ref.watch(findTokenProvider(chipInfo.tokenId).future);
    EthereumAddress connectedWallet = ref.read(userAddressProvider);

    final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
        chainConfig[config.chainId]!.controllerContract);

    //call rarible api
    BigInt priceInPrimaryChainCurrency =
        BigInt.from(this.price * 1000000000000000000);
    RaribleV2Order raribleV2Order = makeRaribleV2Order(
        controllerContractAddress,
        controllerContractAddress,
        config.tokenId,
        controllerContractAddress,
        10000, //TODO: fix this
        10000, //TODO: fix this
        EthereumAddress.fromHex(
            '0x2a3171184e9f73313fd0e61eedbf8f2e33feb552'), //TODO: get this voucher contr. collection from appCollectionProvider
        config.tokenId,
        priceInPrimaryChainCurrency,
        null);
    final typedDataHash = await getRaribleMakeOrderTypedDataHash(
        config.chainId, raribleV2Order); //TODO: check if chainId is needed

    try {
      //check if user is allowed to use gas station
      final List response =
          await checkMetaTx(config.collectionId, offerItemFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      // switch to minting loading overlay
      setState(() {
        isLoading = true;
        overlayContentType = 'loading';
        loadingText = 'Offering token...';
      });

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('OfferOnMPScreen').currentContext!,
            offerItemFunctionSignature,
            config.chainId,
            config.collectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            typedDataHash: typedDataHash,
            controllerContractId: controllerContractAddress,
            tokenId: config.tokenId,
            sellerPayoutAddress: EthereumAddress.fromHex(sellerPayoutAddress),
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'Please connect with MetaMask or similar wallet.';
        }
        //TODO: pass typedDataHash for normal tx
        txnHash = await makeAndSendNormalTx(
          offerItemFunctionSignature,
          config.chainId,
          controllerContractAddress,
          signatureData,
          connectedWallet,
          wc,
          wcSession!,
          walletType!,
          sellerPayoutAddress: EthereumAddress.fromHex(sellerPayoutAddress),
          tokenId: config.tokenId,
        );
      }

      //wait until TX is succeeded or failed
      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);

      //if transaction is mined, then navigate to NFTDetailsScreen
      if (txnReceipt?.status) {
        final MsgSignature? chipSignature =
            await getChipSignature(ref, context, typedDataHash, toggleLoading);
        final String hexSignature = msgSignatureToHex(chipSignature!);

        RaribleV2Order order = raribleV2Order.setSignature(hexSignature);

        var response = await createRaribleOrder(config.chainId, order);
        print(response);

        //call backend with info about offering
        if (currencyDropdownValue == 'EUR') {
          price = await convertEurToToCrypto(price, currencyDropdownValue);
        }
        OfferItemInputDto offerItemInputDto = OfferItemInputDto(
            tokenId: convertTokenIdToEthereumAddress(config.tokenId),
            offerPrice: (BigInt.from(price) * BigInt.from(1000000000000000000))
                .toString(),
            offerCurrency: 'MATIC', //TODO: make dynamic
            sellerWalletAddress:
                ref.read(userSessionProvider)!.userWalletAddress.toString(),
            sellerPayoutAddress: sellerPayoutAddress,
            sellerEmail: email,
            validUntil: 1711688790, //TODO: make dynamic
            typedDataHash: typedDataHash,
            chipSignature: hexSignature,
            marketplaceContract: raribleExchangeContracts[config.chainId]!);

        await sendOfferItemInfoToBackend(offerItemInputDto);

        //TODO: show success message here

        setState(() {
          isRotating = false;
          loadingSvgPath = "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/mint.svg";
          loadingText = 'Item offered';
          isLoading = false;
        });

        //TODO: do stuff on success???
      } else {
        throw Exception('Offer on marketplace failed');
      }
    } catch (e, s) {
      setState(() {
        isLoading = false;
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(
            context.loc.errorHeadingSnackBar, 'Error offering token', 'error'),
      );
    }
  }

  Future convertEurToToCrypto(double price, String cryptoCurrencySymbol) async {
    Map conversionRates =
        await ref.read(ethPriceProvider(allDropdownValues[0]).future);
    return price / conversionRates['EUR'];
  }

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<Map> ethPriceEur =
        ref.watch(ethPriceProvider(allDropdownValues[0]));
    return CustomOverlay(
        show: isLoading,
        content: SpinningLoadingSvg(
          onPressed: () {
            cancellableOperation?.cancel();
            setState(() {
              isLoading = false;
            });
            Navigator.pushNamedAndRemoveUntil(
                context, HomeScreen.routeName, (route) => false);
          },
          loadingText: loadingText,
          rotateIcon: isRotating,
          svgPath: loadingSvgPath,
          // enable secondary button
          secondaryButton: true,
          secondaryButtonText: context.loc.troubleshoot,
          secondaryButtonUrl: dotenv.get('SUPPORT_PAGE_URL'),
        ),
        child: Scaffold(
          key: ScaffoldKey.getScaffoldKey('OfferOnMPScreen'),
          appBar: CustomAppBar(
            text: 'Offer item',
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
                                Text('Email address',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!),
                                const SizedBox(
                                  height: 5,
                                ),
                                TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(
                                      context, 'john@example.com',
                                      fillColor:
                                          CustomColors(dotenv.get('APP_ID'))
                                              .cardColor),
                                  keyboardType: TextInputType.emailAddress,
                                  obscureText: false,
                                  onChanged: (value) {
                                    setState(() {
                                      email = value;
                                    });
                                  },
                                  validator: (value) {
                                    //validate if value is email
                                    bool isEmail = RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value!);
                                    if (isEmail) {
                                      return null;
                                    } else {
                                      return context
                                          .loc.pleaseEnterValidEmailAddress;
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!),
                                const SizedBox(
                                  height: 5,
                                ),
                                TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(context,
                                      'Enter wallet to receive the payment',
                                      fillColor:
                                          CustomColors(dotenv.get('APP_ID'))
                                              .cardColor),
                                  keyboardType: TextInputType.text,
                                  obscureText: false,
                                  onChanged: (value) {
                                    setState(() {
                                      sellerPayoutAddress = value;
                                    });
                                  },
                                  validator: (value) {
                                    try {
                                      EthereumAddress.fromHex(value!);
                                    } catch (e) {
                                      return 'Please enter a valid wallet address';
                                    }
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!),
                                const SizedBox(
                                  height: 5,
                                ),
                                TextFormField(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(
                                      suffix: CryptoCurrencyDropdown(
                                          setCurrency: (value) {
                                            setState(() {
                                              currencyDropdownValue = value;
                                            });
                                          },
                                          selectedCurrency:
                                              currencyDropdownValue),
                                      context,
                                      'Enter sale price for your item',
                                      fillColor:
                                          CustomColors(dotenv.get('APP_ID'))
                                              .cardColor),
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
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
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  '${currencyDropdownValue == 'EUR' ? allDropdownValues[0] : 'EUR'} ${ethPriceEur.when(data: (data) {
                                        if (currencyDropdownValue == 'EUR')
                                          return '${(price / data['EUR']).toStringAsFixed(6)}';
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
                                  style:
                                      Theme.of(context).textTheme.headlineSmall!
                                  // .copyWith(fontWeight: FontWeight.w700),
                                  ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Checkbox(
                                      activeColor: CustomColors(
                                              dotenv.get('APP_ID').toString())
                                          .accentColor,
                                      value: raribleCheck,
                                      onChanged: (value) {
                                        setState(() {
                                          raribleCheck = value!;
                                        });
                                      }),
                                  Text(
                                    'List on Rarible',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
                                    sellerPayoutAddress.isEmpty ||
                                    (price <= 0) ||
                                    (raribleCheck) == false
                                ? null
                                : () async {
                                    //unfocus keyboard
                                    FocusScope.of(context).unfocus();
                                    if (_formKey.currentState!.validate()) {
                                      fromCancelable(offerToken());
                                    }
                                  },
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 300,
                                child: Text(
                                  'OwnerChip will notify you via email once the item is purchased. You are responsible for packaging and shipping the item to the buyer.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          )
                        ],
                      )),
                ],
              )),
        ));
  }
}
