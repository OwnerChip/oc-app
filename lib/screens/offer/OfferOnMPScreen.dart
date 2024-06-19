//import packages

import 'dart:math';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:info_popup/info_popup.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/chipInfoModel/chipInfoModel.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleConsts.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleV2Order/raribleV2Order.dart';
import 'package:ownerchip_whitelabel/domain/signatureData/signatureData.dart';
import 'package:ownerchip_whitelabel/domain/tokenChainAndCollection/tokenChainAndCollection.dart';
import 'package:ownerchip_whitelabel/domain/userSession/userSession.dart';
import 'package:ownerchip_whitelabel/domain/walletType/walletType.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/screens/offer/OfferForSaleCreatedTokenScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/backendMetaTx.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/backendOffer.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/payloads/offerItemPayload.dart';
import 'package:ownerchip_whitelabel/services/ipfs.services.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/offerOnMp/offerOnMpNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/rarible.services.dart';
import 'package:ownerchip_whitelabel/services/rarible/orders/raribleOrders.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCheckBox.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/LoadingIndicator.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:collection/collection.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CryptoCurrencyDropdown.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3modal_flutter/services/w3m_service/models/w3m_session.dart';

class OfferOnMPScreen extends ConsumerStatefulWidget {
  const OfferOnMPScreen({Key? key}) : super(key: key);

  static const routeName = '/offerOnMp';

  @override
  _OfferOnMPScreen createState() => _OfferOnMPScreen();
}

class _OfferOnMPScreen extends ConsumerState<OfferOnMPScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  CancelableOperation? cancellableOperation;
  bool isLoading = false;
  String loadingText = '';
  String overlayContentType = 'loading';
  String email = '';
  double price = 0.00;
  String loadingSvgPath =
      '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/chip_dark_blue.svg';
  bool isRotating = true;
  String currencyDropdownValue = 'MATIC';
  bool raribleCheck = true;
  bool _legalHintCheck = false;

  List<String> allDropdownValues = [];
  Future<bool>?
      _setCurrencyDropDownValuesFuture; //future used for currency dropdown FutureBuilder

  bool _canOffer() {
    return email.isEmpty ||
        !_legalHintCheck ||
        (price <= 0) ||
        (raribleCheck) == false;
  }

  @override
  void initState() {
    super.initState();
    _setCurrencyDropDownValuesFuture = setCurrencyDropDownValues();
    _initCreatorData();
  }

  void _initCreatorData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final current = ref.read(offerOnMpProvider);
      String initialEmail = "";

      if (current.creatorDto != null) {
        initialEmail = current.creatorDto!.email;
      } else {
        await ref.read(offerOnMpProvider.notifier).init().then((_) {
          initialEmail = ref.read(offerOnMpProvider).creatorDto?.email ?? '';
        });
      }

      _emailController.text = initialEmail;
      email = initialEmail;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<bool> setCurrencyDropDownValues() async {
    ChipInfoModel chipInfo = ref.read(chipInfoProvider);
    final TokenChainAndCollection config =
        await ref.read(findTokenProvider(chipInfo.tokenId).future);
    String currencySymbol = chainConfig[config.chainId]!.nativeTokenSymbol;
    final tokens = chainTokenConfigs[config.chainId]!;
    setState(() {
      allDropdownValues = [
        currencySymbol,
        // ...tokens.map((token) => token.symbol),
      ];
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
    final List response = await BackendMetaTx.checkMetaTx(
        twinCollectionId, mintFunctionSignature);
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

      String txnHash = "";

      Future<void> normalTx() async {
        txnHash = await makeAndSendNormalTx(
          context,
          ref,
          mintVoucherFunctionSignature,
          chainId,
          voucherCollectionId,
          signatureData,
          connectedWallet,
          wc!,
          wcSession,
          walletType!,
          twinTokenMetadataCID: twinTokenMetadataCID,
          voucherTokenMetadataCID: voucherTokenMetadataCID,
        );
      }

      try {
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

          await normalTx();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        talker.error(e, st);
        talker.error(
            'Minting voucher token failed with gassless tx, trying normal tx.');
        await normalTx();
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

    final token = chainTokenConfigs[config.chainId]!.firstWhereOrNull(
      (element) => element.symbol == currencyDropdownValue,
    );

    final double priceInPrimaryChainCurrency;

    if (token == null) {
      priceInPrimaryChainCurrency = price * 1000000000000000000;
    } else {
      priceInPrimaryChainCurrency = price * (pow(10, token.decimals));
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

    RaribleV2Order raribleV2Order = RaribleV2Order.makeRaribleV2Order(
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
      null,
      config.chainId,
      token,
    );
    final typedDataHashAndEncodedData =
        await getRaribleOrderTypedDataHash(config.chainId, raribleV2Order);
    final typedDataHash = typedDataHashAndEncodedData.typedDataHash;

    final MsgSignature? chipSignature = await getChipSignature(
      ref,
      context,
      typedDataHash,
      toggleLoading,
    );
    final String hexSignature = msgSignatureToHex(chipSignature!);

    try {
      //check if user is allowed to use gas station
      final List response = await BackendMetaTx.checkMetaTx(
          config.collectionId, offerItemFunctionSignature);
      final bool canUseGasStation = response[0];
      final metaTxAgreementId = response[1];

      String txnHash = "";

      Future<void> normalTx() async {
        txnHash = await makeAndSendNormalTx(
          context,
          ref,
          offerItemFunctionSignature,
          config.chainId,
          controllerContractAddress,
          signatureData,
          connectedWallet,
          wc!,
          wcSession,
          walletType!,
          sellerPayoutAddress: userSession.userWalletAddress,
          tokenId: config.tokenId,
          typedDataHash: typedDataHash,
          price: BigInt.from(priceInPrimaryChainCurrency),
        );
      }

      try {
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
              sellerPayoutAddress: userSession.userWalletAddress,
              salt: raribleV2Order.salt,
              endTimestamp: raribleV2Order.end,
              price: BigInt.from(priceInPrimaryChainCurrency),
              encodedOfferData: typedDataHashAndEncodedData.encodedData,
              toggleLoading: toggleLoading);
        } else {
          if (wc == null) {
            throw 'Please connect with MetaMask or similar wallet.';
          }
          await normalTx();
        }
      } catch (e, st) {
        Sentry.captureException(e, stackTrace: st);
        talker.error(e, st);
        talker
            .error('Offering token failed with gassless tx, trying normal tx.');
        await normalTx();
      }

      talker.info("Transaction hash: $txnHash");

      //wait until TX is succeeded or failed
      var txnReceipt =
          await getTxnReceipt(getRPCUrlFromChainId(config.chainId), txnHash);

      //if transaction is mined, then navigate to NFTDetailsScreen
      if (txnReceipt?.status == true) {
        RaribleV2Order order = raribleV2Order.setSignature(hexSignature);

        await Future.delayed(const Duration(seconds: 2));
        var response = await RaribleOrders.createRaribleOrder(
          chainId: config.chainId,
          order: order,
        );

        //call backend with info about offering
        final offerItemInputData = OfferItemPayload(
            tokenId: convertTokenIdToEthereumAddress(config.tokenId),
            offerPrice: priceInPrimaryChainCurrency.toString(),
            offerCurrency: chainConfig[config.chainId]!.nativeTokenSymbol,
            sellerWalletAddress:
                ref.read(userSessionProvider)!.userWalletAddress.toString(),
            sellerPayoutAddress: userSession.userWalletAddress.hex,
            sellerEmail: email,
            validUntil: raribleV2Order.end,
            salt: raribleV2Order.salt.toString(),
            encodedData: typedDataHashAndEncodedData.encodedData,
            typedDataHash: typedDataHash,
            chipSignature: hexSignature,
            marketplaceContract: raribleExchangeV2Contracts[config.chainId]!,
            offchainOfferId: response['id']);

        await BackendOffer.sendOfferItemInfoToBackend(offerItemInputData);

        BackendApp.sendAnalyticsTrace(
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
          context.loc.offerOnMpPublishedDialogTitle,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.loc.offerOnMpPublishedDialogSubtitle,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color:
                          CustomColors(dotenv.get('APP_ID')).black.withOpacity(
                                0.7,
                              ),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomRoundedButton(
                text: context.loc.viewOnMP,
                onPressed: () {
                  launchUrl(Uri.parse(raribleTokenUrl),
                      mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(
                height: 8,
              ),
            ],
          ),
          icon: Icon(Icons.celebration,
              size: 90, color: CustomColors(dotenv.get('APP_ID')).accentColor),
          titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
          titlePadding: const EdgeInsets.all(0),
          showConfetti: true,
        );

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
      BackendApp.sendAnalyticsTrace(
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

  Future<dynamic> fromCancelable(Future<dynamic> future) async {
    cancellableOperation?.cancel();
    cancellableOperation =
        CancelableOperation.fromFuture(future, onCancel: () {});
    return cancellableOperation;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AsyncValue<Map> ethPriceEur =
        ref.watch(ethPriceProvider(currencyDropdownValue));
    final offerOnMpData = ref.watch(offerOnMpProvider);
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
        child: Stack(children: [
          Scaffold(
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
                                  Row(
                                    children: [
                                      Text(context.loc.emailAddress,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall!),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      InfoPopupWidget(
                                        key: const Key('emailInfoPopup'),
                                        arrowTheme: InfoPopupArrowTheme(
                                          arrowDirection: ArrowDirection.down,
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .primaryColor,
                                        ),
                                        contentTitle:
                                            context.loc.offerOnMpEmailHint,
                                        child: Icon(
                                            color: CustomColors(
                                                    dotenv.get('APP_ID'))
                                                .primaryColor,
                                            Icons.info,
                                            size: 18),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  TextFormField(
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
                                    controller: _emailController,
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
                                        contentTitle:
                                            context.loc.offerOnMpPriceHint,
                                        child: Icon(
                                            color: CustomColors(
                                                    dotenv.get('APP_ID'))
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
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
                                                    currencyDropdownValue =
                                                        value;
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
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    obscureText: false,
                                    initialValue: price.toString(),
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
                                    ethPriceEur.when(
                                        data: (data) {
                                          String priceInEur = '';
                                          if (currencyDropdownValue == 'EUR') {
                                            priceInEur = (price / data['EUR'])
                                                .toStringAsFixed(6);
                                          } else {
                                            priceInEur = (price * data['EUR'])
                                                .toStringAsFixed(2);
                                          }

                                          return context.loc
                                              .offerOnMpEstimatedPriceInEur(
                                                  priceInEur);
                                        },
                                        error: (e, s) => context
                                            .loc.offerOnMpErrorFetchingPrice,
                                        loading: () =>
                                            context.loc.offerOnMpFetchingPrice),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color:
                                              CustomColors(dotenv.get('APP_ID'))
                                                  .black
                                                  .withOpacity(.7),
                                        ),
                                  ),
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
                            Row(
                              children: [
                                CustomCheckBox(
                                  value: _legalHintCheck,
                                  onChanged: (value) {
                                    setState(() {
                                      _legalHintCheck = value;
                                    });
                                  },
                                ),
                                Flexible(
                                  child: Text(
                                    context.loc.legalHintTerrorismFinancing,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 32,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0,
                                  ),
                                  child: Text(
                                    context.loc.shippingHint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                CustomRoundedButton(
                                  text: context.loc.offerNow,
                                  onPressed: _canOffer()
                                      ? null
                                      : () async {
                                          //unfocus keyboard
                                          FocusScope.of(context).unfocus();
                                          if (_formKey.currentState!
                                              .validate()) {
                                            fromCancelable(offerToken());
                                          }
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                          ],
                        )),
                  ],
                )),
          )
        ]));
  }
}
