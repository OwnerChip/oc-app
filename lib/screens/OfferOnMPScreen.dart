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
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
import 'package:ownerchip_whitelabel/services/scan.services.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/LoadingIndicator.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _sellerPayoutInputController = TextEditingController();

  CancelableOperation? cancellableOperation;
  bool isLoading = false;
  String loadingText = '';
  String overlayContentType = 'loading';
  String email = '';
  String sellerPayoutAddress = '';
  double price = 0.00;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  bool isRotating = true;
  String currencyDropdownValue = 'MATIC';
  bool raribleCheck = true;
  List<String> allDropdownValues = [
    'MATIC',
    'EUR'
  ]; //attention: order of items is important
  Future<bool>?
      _setCurrencyDropDownValuesFuture; //future used for currency dropdown FutureBuilder
  //initState
  @override
  void initState() {
    super.initState();

    _setCurrencyDropDownValuesFuture = setCurrencyDropDownValues();

    UserSession? userSession = ref.read(userSessionProvider);
    if (userSession != null && !userSession.isOwnerCard) {
      _sellerPayoutInputController.value = TextEditingValue(
          text: userSession.userWalletAddress.toString(),
          selection: TextSelection.fromPosition(TextPosition(
              offset: userSession.userWalletAddress.toString().length)));
      setState(() {
        sellerPayoutAddress = userSession.userWalletAddress.hex;
      });
    }
  }

  Future<bool> setCurrencyDropDownValues() async {
    ChipInfoModel chipInfo = ref.read(chipInfoProvider);
    final TokenChainAndCollection config =
        await ref.read(findTokenProvider(chipInfo.tokenId).future);
    String currencySymbol = chainConfig[config.chainId]!.nativeTokenSymbol;
    setState(() {
      allDropdownValues = [currencySymbol, 'EUR'];
      currencyDropdownValue = currencySymbol;
    });
    return true;
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
    final TokenChainAndCollection config =
        await ref.watch(findTokenProvider(chipInfo.tokenId).future);
    EthereumAddress connectedWallet = ref.read(userAddressProvider);
    final EthereumAddress controllerContractAddress = EthereumAddress.fromHex(
        chainConfig[config.chainId]!.controllerContract);

    final double priceInPrimaryChainCurrency;
    if (currencyDropdownValue == 'EUR') {
      priceInPrimaryChainCurrency =
          await convertEurToToCrypto(price, allDropdownValues[0]) *
              1000000000000000000;
    } else {
      priceInPrimaryChainCurrency = price * 1000000000000000000;
    }

    EthereumAddress? voucherContractAddress =
        await ref.read(voucherContractProvider.future);
    RaribleV2Order raribleV2Order = makeRaribleV2Order(
        controllerContractAddress,
        controllerContractAddress,
        config.tokenId,
        controllerContractAddress,
        10000, //TODO: fix this
        0, //TODO: fix this
        voucherContractAddress!,
        config.tokenId,
        BigInt.from(priceInPrimaryChainCurrency),
        null);
    final typedDataHashAndEncodedData =
        await getRaribleOrderTypedDataHash(config.chainId, raribleV2Order);
    final typedDataHash = typedDataHashAndEncodedData.typedDataHash;

    final MsgSignature? chipSignature =
        await getChipSignature(ref, context, typedDataHash, toggleLoading);
    final String hexSignature = msgSignatureToHex(chipSignature!);

    setState(() {
      isLoading = true;
      overlayContentType = context.loc.loading;
      loadingText = context.loc.offeringToken;
    });

    try {
      //check if user is allowed to use gas station
      final List response =
          await checkMetaTx(config.collectionId, offerItemFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

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
            salt: raribleV2Order.salt,
            endTimestamp: raribleV2Order.end,
            price: BigInt.from(priceInPrimaryChainCurrency),
            encodedOfferData: typedDataHashAndEncodedData.encodedData,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'Please connect with MetaMask or similar wallet.';
        }
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
          typedDataHash: typedDataHash,
          price: BigInt.from(priceInPrimaryChainCurrency),
        );
      }

      //wait until TX is succeeded or failed
      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);

      //if transaction is mined, then navigate to NFTDetailsScreen
      if (txnReceipt?.status) {
        RaribleV2Order order = raribleV2Order.setSignature(hexSignature);

        var response = await createRaribleOrder(config.chainId, order);

        //call backend with info about offering
        OfferItemInputData offerItemInputData = OfferItemInputData(
            tokenId: convertTokenIdToEthereumAddress(config.tokenId),
            offerPrice: priceInPrimaryChainCurrency.toString(),
            offerCurrency: chainConfig[config.chainId]!.nativeTokenSymbol,
            sellerWalletAddress:
                ref.read(userSessionProvider)!.userWalletAddress.toString(),
            sellerPayoutAddress: sellerPayoutAddress,
            sellerEmail: email,
            validUntil: raribleV2Order.end,
            salt: raribleV2Order.salt.toString(),
            encodedData: typedDataHashAndEncodedData.encodedData,
            typedDataHash: typedDataHash,
            chipSignature: hexSignature,
            marketplaceContract: raribleExchangeV2Contracts[config.chainId]!);

        await sendOfferItemInfoToBackend(offerItemInputData);

        await Future.delayed(Duration(seconds: 2));

        //refresh providers for ownerchip check on ResultScreen
        await ref.refresh(nftOwnerProvider.future);
        await ref.refresh(creatorDataProvider.future);
        await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);

        setState(() {
          isLoading = false;
        });

        String raribleTokenUrl = makeRaribleTokenPageUrl(
            config.chainId, voucherContractAddress, config.tokenId);

        Navigator.pop(context);

        // ignore: use_build_context_synchronously
        showCustomPopup(
            context,
            context.loc.itemOfferedOnMP,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                CustomRoundedButton(
                    text: context.loc.viewOnMP,
                    onPressed: () {
                      launchUrl(Uri.parse(raribleTokenUrl),
                          mode: LaunchMode.externalApplication);
                    }),
                // const SizedBox(height: 10),
                // CustomOutlinedButton(
                //     onPressed: () {
                //       Navigator.pop(
                //           ScaffoldKey.getScaffoldKey('UserScanResultsScreen')
                //               .currentContext!);
                //     },
                //     buttonText: context.loc.done)
              ],
            ),
            icon: Icon(Icons.celebration,
                size: 90,
                color: CustomColors(dotenv.get('APP_ID')).accentColor),
            titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize:
                    CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
                //no margin
                color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                fontWeight:
                    CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
            titlePadding: const EdgeInsets.all(0));

        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(context.loc.successHeadingSnackbar,
              context.loc.itemOffered, 'success'),
        );
      } else {
        throw Exception('Offer on marketplace failed');
      }
    } catch (e, s) {
      setState(() {
        isLoading = false;
      });
      await Sentry.captureException(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        returnSnackBarWidget(context.loc.errorHeadingSnackBar,
            context.loc.errorOfferingToken, 'error'),
      );
    }
  }

  Future<double> convertEurToToCrypto(
      double price, String cryptoCurrencySymbol) async {
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
  void dispose() {
    _sellerPayoutInputController.dispose();
    super.dispose();
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
        ),
        child: Scaffold(
          key: ScaffoldKey.getScaffoldKey('OfferOnMPScreen'),
          appBar: CustomAppBar(
            text: context.loc.offerItem,
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
                                Text(context.loc.emailAddress,
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
                                Text(context.loc.walletAddress,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!),
                                const SizedBox(
                                  height: 5,
                                ),
                                TextFormField(
                                  controller: _sellerPayoutInputController,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  cursorColor: CustomColors(
                                          dotenv.get('APP_ID').toString())
                                      .accentColor,
                                  decoration: customInputDecoration(context,
                                      context.loc.enterWalletAddressForPayout,
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
                                      return context
                                          .loc.pleaseEnterValidWalletAddress;
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
                                Text(context.loc.price,
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
                                      suffix: FutureBuilder<bool>(
                                        future:
                                            _setCurrencyDropDownValuesFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return CryptoCurrencyDropdown(
                                              allDropDownItems:
                                                  allDropdownValues,
                                              setCurrency: (value) {
                                                setState(() {
                                                  currencyDropdownValue = value;
                                                });
                                              },
                                              selectedCurrency:
                                                  currencyDropdownValue,
                                            );
                                          } else if (snapshot.hasError) {
                                            return Container();
                                          } else {
                                            return Container();
                                          }
                                        },
                                      ),
                                      context,
                                      context.loc.enterSalePrice,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall!),
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
                                    context.loc.listOnRarible,
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
                            text: context.loc.offerNow,
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
