//import packages

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:info_popup/info_popup.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
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
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CryptoCurrencyDropdown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:web3modal_flutter/services/w3m_service/models/w3m_session.dart';

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
  ]; //TODO: support other currencies //attention: order of items is important
  Future<bool>?
      _setCurrencyDropDownValuesFuture; //future used for currency dropdown FutureBuilder

  @override
  void initState() {
    super.initState();

    _setCurrencyDropDownValuesFuture = setCurrencyDropDownValues();

    UserSession? userSession = ref.read(userSessionProvider);
    if (userSession != null) {
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

  Future<void> mintVoucherToken(
      int chainId,
      EthereumAddress twinCollectionId,
      EthereumAddress voucherCollectionId,
      TokenChainAndCollection config,
      SignatureData signatureData,
      EthereumAddress connectedWallet,
      Web3App? wc,
      W3MSession? wcSession,
      UserSession userSession,
      WalletType? walletType) async {
    //check if user is allowed to use gas station
    final List response =
        await checkMetaTx(twinCollectionId, mintFunctionSignature);
    final bool canUseGasStation = response[0];
    final metaTxAgreementId = response[1];

    try {
      // get tokenUri from twin token
      String twinTokenUri = await getTokenUri(
          getRPCUrlFromChainId(config.chainId),
          config.collectionId,
          config.tokenId);
      String twinTokenMetadataCID = getCidFromIpfsLink(twinTokenUri);
      Map<String, dynamic> twinTokenMetadata =
          await downloadMetadataFromIPFS(twinTokenMetadataCID);

      // generate voucher token metadata and upload to IPFS
      String voucherTokenMetadataCID = '';
      Map<String, dynamic> voucherTokenMetadata = twinTokenMetadata;
      voucherTokenMetadata['description'] +=
          "\n\n ${context.loc.voucherNftDescriptionGeneral}, ${context.loc.voucherNftDescriptionAppSpecific}";
      XFile jsonFileVoucher =
          await saveMetadataAsJSONFile(voucherTokenMetadata);
      voucherTokenMetadataCID =
          await uploadFileToIPFS(jsonFileVoucher, 'application/json');

      String txnHash;
      if (canUseGasStation) {
        txnHash = await makeAndSendGaslessTx(
            ref,
            ScaffoldKey.getScaffoldKey('OfferOnMPScreen').currentContext!,
            mintVoucherFunctionSignature,
            chainId,
            voucherCollectionId,
            signatureData,
            connectedWallet,
            wc,
            wcSession,
            metaTxAgreementId,
            walletType!,
            twinTokenMetadataCID: twinTokenMetadataCID,
            voucherTokenMetadataCID: voucherTokenMetadataCID,
            toggleLoading: toggleLoading);
      } else {
        if (userSession.isOwnerCard) {
          throw 'Gas station needed for TX with OwnerCard.';
        }
        if (wc == null) {
          throw 'Please connect with MetaMask or similar wallet.';
        }
        txnHash = await makeAndSendNormalTx(
          ref,
          mintVoucherFunctionSignature,
          chainId,
          voucherCollectionId,
          signatureData,
          connectedWallet,
          wc,
          wcSession,
          walletType!,
          twinTokenMetadataCID: twinTokenMetadataCID,
          voucherTokenMetadataCID: voucherTokenMetadataCID,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> offerToken() async {
    final Web3App? wc = ref.read(wcProvider);
    final SignatureData signatureData = ref.read(chipSignatureDataProvider);
    final UserSession userSession = ref.read(userSessionProvider)!;
    final W3MSession? wcSession = ref.read(wcSessionProvider);
    final WalletType? walletType = ref.read(walletTypeProvider);
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
    setState(() {
      isLoading = true;
      overlayContentType = context.loc.loading;
    });

    final voucherContractAddress =
        await ref.read(voucherContractProvider.future);

    //check if voucher token exists
    final voucherTokenOwner = await getVoucherOwner(
      getRPCUrlFromChainId(config.chainId),
      voucherContractAddress!,
      config.tokenId,
    );

    if (voucherTokenOwner == null) {
      setState(() {
        loadingText = context.loc.mintingVoucherToken;
      });
      await mintVoucherToken(
          config.chainId,
          config.collectionId,
          voucherContractAddress,
          config,
          signatureData,
          connectedWallet,
          wc,
          wcSession,
          userSession,
          walletType);
    }

    setState(() {
      loadingText = context.loc.offeringToken;
    });

    RaribleV2Order raribleV2Order = makeRaribleV2Order(
        controllerContractAddress,
        controllerContractAddress,
        config.tokenId,
        controllerContractAddress,
        10000,
        //TODO: fix this
        0,
        //TODO: fix this
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
          ref,
          offerItemFunctionSignature,
          config.chainId,
          controllerContractAddress,
          signatureData,
          connectedWallet,
          wc,
          wcSession,
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

        await Future.delayed(const Duration(seconds: 2));
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
            marketplaceContract: raribleExchangeV2Contracts[config.chainId]!,
            offchainOfferId: response['id']);

        await sendOfferItemInfoToBackend(offerItemInputData);

        sendAnalyticsTrace(
            userSession.sessionId, txnHash, "TOKEN_OFFER_SUCCESS",
            tags: {
              'connectedWallet': ref.read(userAddressProvider).hex,
              'chipWallet': convertTokenIdToEthereumAddress(
                  ref.read(chipInfoProvider).tokenId),
            });

        try {
          await Future.delayed(const Duration(seconds: 2));
          //refresh providers for ownerchip check on ResultScreen
          await ref.refresh(nftOwnerProvider.future);
          await ref.refresh(creatorDataProvider.future);
          await ref.refresh(voucherContractAndTwinNftOwnerProvider.future);
          await ref.refresh(voucherTokenOwnerProvider.future);
          await ref.refresh(activeOffersProvider.future);
        } catch (e) {
          print(e);
          Sentry.captureException(e);
        }

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
      sendAnalyticsTrace(
          userSession.sessionId, e.toString(), "TOKEN_OFFER_ERROR",
          tags: {
            'connectedWallet': ref.read(userAddressProvider).hex,
            'chipWallet': convertTokenIdToEthereumAddress(
                ref.read(chipInfoProvider).tokenId),
          });
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
            Navigator.of(context).popUntil((route) => route.isFirst);
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
                                Text(context.loc.payoutWalletAddress,
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
                                Row(
                                  children: [
                                    Text(context.loc.price,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall!),
                                    const SizedBox(width: 5),
                                    InfoPopupWidget(
                                      key: const Key('feeInfoPopup'),
                                      arrowTheme: InfoPopupArrowTheme(
                                        arrowDirection: ArrowDirection.down,
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .primaryColor,
                                      ),
                                      contentTitle: context.loc.feesInfo,
                                      child: Icon(
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .primaryColor,
                                          Icons.info,
                                          size: 18),
                                    ),
                                  ],
                                ),
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
                          //TODO: checkbox for selecting Marketplace temporarily disabled
                          // Column(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     Text('Marketplace',
                          //         style: Theme.of(context)
                          //             .textTheme
                          //             .headlineSmall!),
                          //     Row(
                          //       mainAxisAlignment: MainAxisAlignment.start,
                          //       children: [
                          //         Checkbox(
                          //             activeColor: CustomColors(
                          //                     dotenv.get('APP_ID').toString())
                          //                 .accentColor,
                          //             value: raribleCheck,
                          //             onChanged: (value) {
                          //               setState(() {
                          //                 raribleCheck = value!;
                          //               });
                          //             }),
                          //         Text(
                          //           context.loc.listOnRarible,
                          //           style:
                          //               Theme.of(context).textTheme.bodyMedium,
                          //         )
                          //       ],
                          //     ),
                          //   ],
                          // ),
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
                                  context.loc
                                      .ownerChipWillNotifyYouOnceTheItemIsPurchased,
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
