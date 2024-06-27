import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/screens/EnterShippingAddressScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/token/backendToken.dart';
import 'package:ownerchip_whitelabel/services/gasstation.services.dart';
import 'package:ownerchip_whitelabel/services/providers/purchasesData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

Web3Client getWeb3Client(String chainRpcUrl) {
  var client = Web3Client(chainRpcUrl, Client());
  return client;
}

Future<DeployedContract> getControllerContract(
    EthereumAddress collectionId) async {
  String abi =
      await rootBundle.loadString("assets/contracts/controller.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'OwnerChipController'),
    collectionId,
  );
  return contract;
}

Future<DeployedContract> getCollectionContract(
    EthereumAddress collectionId) async {
  String abi =
      await rootBundle.loadString("assets/contracts/collection.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'OwnerChipDemo'),
    collectionId,
  );
  return contract;
}

Future<DeployedContract> getVoucherContract(
    EthereumAddress collectionId) async {
  String abi = await rootBundle.loadString("assets/contracts/voucher.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'OwnerChipVoucher'),
    collectionId,
  );
  return contract;
}

Future<DeployedContract> getRegistryContract(
    String registryContractAddress) async {
  String abi =
      await rootBundle.loadString("assets/contracts/registry.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'OwnerChipRegistry'),
    EthereumAddress.fromHex(registryContractAddress),
  );
  return contract;
}

Future<DeployedContract> getForwarderContract(
    String registryForwarderAddress) async {
  String abi =
      await rootBundle.loadString("assets/contracts/forwarder.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, 'MinimalForwarder'),
    EthereumAddress.fromHex(registryForwarderAddress),
  );
  return contract;
}

Future<List<dynamic>> queryRegistryContract(
    String chainRpcUrl,
    String registryContractAddress,
    String functionName,
    List<dynamic> args) async {
  DeployedContract contract =
      await getRegistryContract(registryContractAddress);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<List<dynamic>> queryCollectionContract(
    String chainRpcUrl,
    EthereumAddress collectionId,
    String functionName,
    List<dynamic> args) async {
  try {
    DeployedContract contract = await getCollectionContract(collectionId);
    ContractFunction function = contract.function(functionName);
    final web3Client = getWeb3Client(chainRpcUrl);
    final result = await web3Client.call(
        contract: contract, function: function, params: args);
    return result;
  } catch (e) {
    rethrow;
  }
}

Future<List<dynamic>> queryVoucherContract(
    String chainRpcUrl,
    EthereumAddress voucherContractAddress,
    String functionName,
    List<dynamic> args) async {
  DeployedContract contract = await getVoucherContract(voucherContractAddress);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  final result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<List<dynamic>> queryForwarderContract(
    String chainRpcUrl,
    String registryForwarderAddress,
    String functionName,
    List<dynamic> args) async {
  DeployedContract contract =
      await getForwarderContract(registryForwarderAddress);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<List<dynamic>> queryControllerContract(
    String chainRpcUrl,
    EthereumAddress controllerContractAddress,
    String functionName,
    List<dynamic> args) async {
  DeployedContract contract =
      await getControllerContract(controllerContractAddress);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<BigInt> estimateGas(
  String chainRpcUrl,
  EthereumAddress contractAddress,
  Uint8List? txData,
  EthereumAddress fromAddress, {
  EtherAmount? value,
  EtherAmount? gasPrice,
}) async {
  final web3Client = getWeb3Client(chainRpcUrl);
  BigInt result = await web3Client.estimateGas(
    sender: fromAddress,
    to: contractAddress,
    data: txData,
    value: value,
    gasPrice: gasPrice,
  );
  return result;
}

Future<BigInt> estimateGasPrice(String chainRpcUrl) async {
  final web3Client = getWeb3Client(chainRpcUrl);
  EtherAmount gasPrice = await web3Client.getGasPrice();
  return gasPrice.getInWei;
}

Future<BigInt> getNonce(String chainRpcUrl, String registryContractAddress,
    String fromAddress) async {
  try {
    var nonce = await queryForwarderContract(
        chainRpcUrl,
        registryContractAddress,
        "getNonce",
        [EthereumAddress.fromHex(fromAddress)]);
    return nonce[0];
  } catch (e) {
    print('Error while fetching nonce: $e');
    throw Exception('Error while fetching nonce: $e');
  }
}

// contract version 2
Future<bool> verifyTokenSigner(
    String chainRpcUrl,
    EthereumAddress collectionId,
    EthereumAddress chipWalletAddressHex,
    Uint8List randomValueHash,
    MsgSignature signature) async {
  Uint8List r = bytesFromBigInt(signature.r);
  Uint8List s = bytesFromBigInt(signature.s);
  try {
    var result = await queryCollectionContract(chainRpcUrl, collectionId,
        "getSigner", [randomValueHash, r, s, BigInt.from(signature.v)]);
    bool res = (chipWalletAddressHex ==
        EthereumAddress.fromHex(result[0].toString().toLowerCase()));
    return res;
  } catch (e) {
    return false;
  }
}

String makeMintData(String functionSignatureHash, Uint8List hash,
    MsgSignature signature, String tokenURI, String? voucherTokenURI) {
  String data = (functionSignatureHash == mintVoucherFunctionSignature &&
          voucherTokenURI != null &&
          voucherTokenURI != "")
      ?
      // voucherToken mint calldata
      functionSignatureHash +
          uint8ListTo32ByteHex(hash) + //bytes32
          "c0".padLeft(64, '0') + //string1 position
          //position of string2 is string1 position + 96 bytes (3 lines below in call data)
          (0xc0 + 96).toRadixString(16).padLeft(64, '0') + //string2 position
          signature.r.toRadixString(16).padLeft(64, '0') + //bytes32
          signature.s.toRadixString(16).padLeft(64, '0') + //bytes32
          signature.v.toRadixString(16).padLeft(64, '0') + //uint8
          (tokenURI.length).toRadixString(16).padLeft(64, '0') +
          stringToHex(tokenURI) + //string1;
          (voucherTokenURI.length).toRadixString(16).padLeft(64, '0') +
          stringToHex(voucherTokenURI) //string2;
      // twinToken mint calldata
      : functionSignatureHash +
          uint8ListTo32ByteHex(hash) + //bytes32
          "a0".padLeft(64, '0') + //string prefix
          signature.r.toRadixString(16).padLeft(64, '0') + //bytes32
          signature.s.toRadixString(16).padLeft(64, '0') + //bytes32
          signature.v.toRadixString(16).padLeft(64, '0') + //uint8
          (tokenURI.length).toRadixString(16).padLeft(64, '0') +
          stringToHex(tokenURI); //string;
  return data;
}

Future<List<dynamic>> buildEthSendTransactionRequest(
  String chainRpcUrl,
  EthereumAddress collectionId,
  EthereumAddress? from,
  String functionSignatureHash,
  Uint8List randomValueHash,
  MsgSignature signature, {
  EthereumAddress? toAccount,
  String? tokenURI,
  String? voucherTokenURI,
  BigInt? tokenId,
  bool? enableRecovery,
  EthereumAddress? sellerPayoutAddress,
  BigInt? offerPrice,
  String? typedDataHash,
  BigInt? salt,
  int? end,
  String? encodedOfferData,
  int? chainId,
  BigInt? amount,
  String? offerHash,
  BigInt? gasAmount,
  BigInt? gasPrice,
}) async {
  String? data;
  if (functionSignatureHash == mintFunctionSignature) {
    data = makeMintData(
        functionSignatureHash, randomValueHash, signature, tokenURI!, null);
  } else if (functionSignatureHash == erc20TransferFunctionSignature) {
    data = makeErc20TransferData(
      functionSignatureHash,
      toAccount!,
      amount!,
    );
  } else if (amount != null) {
    data = null;
  } else if (functionSignatureHash == mintVoucherFunctionSignature) {
    data = makeMintData(functionSignatureHash, randomValueHash, signature,
        tokenURI!, voucherTokenURI!);
  } else if (functionSignatureHash == burnFunctionSignature) {
    data = makeBurnData(functionSignatureHash, randomValueHash, signature);
  } else if (functionSignatureHash == transferFromFunctionSignature) {
    data = makeTransferFromData(
        functionSignatureHash, randomValueHash, signature, enableRecovery);
  } else if (functionSignatureHash == approveFunctionSignature) {
    data = makeApproveData(functionSignatureHash, tokenId!, toAccount!);
  } else if (functionSignatureHash == offerItemFunctionSignature) {
    data = makeOfferItemData(
        functionSignatureHash,
        tokenId!,
        EthereumAddress.fromHex(raribleTransferProxies[chainId]!),
        sellerPayoutAddress!,
        offerPrice!,
        typedDataHash!);
  } else if (functionSignatureHash == redeemItemFunctionSignature) {
    data = makeRedeemTwinTokenData(
        functionSignatureHash, randomValueHash, signature, offerHash!);
  } else if (functionSignatureHash == recoverTokenFunctionSignature) {
    data =
        makeRecoverTokenData(functionSignatureHash, randomValueHash, signature);
  } else if (functionSignatureHash == cancelMarketplaceOfferSignature) {
    data = makeCancelOfferData(
        functionSignatureHash,
        EthereumAddress.fromHex(raribleExchangeV2Contracts[chainId]!),
        randomValueHash,
        signature,
        encodedOfferData!);
  } else {
    throw Exception('Invalid function signature hash');
  }

  String gasAmountStr =
      "0x${gasAmount != null ? gasAmount.toRadixString(16) : "55730"}"; // fallback: 300000 gas
  try {
    if (gasAmount == null) {
      BigInt gasAmountEst = await estimateGas(
        chainRpcUrl,
        collectionId,
        data != null ? hexToBytes(data) : null,
        from!,
      );
      gasAmountStr = "0x${gasAmountEst.toRadixString(16)}";
    }
    ;
    print("ESTIMATED GAS AMOUNT: $gasAmount");
  } catch (e) {
    print("ERROR estimating gas amount: $e");
  }

  String gasPriceStr;

  if (gasPrice == null) {
    try {
      gasPrice = await estimateGasPrice(chainRpcUrl);
      print("ESTIMATED GAS PRICE: $gasPrice");
      gasPriceStr = "0x${gasPrice.toRadixString(16)}";
    } catch (e) {
      print("ERROR estimating gas price: $e");
      gasPriceStr = dotenv.get('DEFAULT_GAS_PRICE'); // fallback
    }
  } else {
    gasPriceStr = "0x${gasPrice.toRadixString(16)}";
  }

  final params = [
    {
      "from": from.toString(),
      "to": collectionId.toString(),
      "gasPrice": gasPriceStr,
      "gas": gasAmountStr,
    },
  ];

  // print("GasPrice: ${BigInt.parse(gasPriceStr.substring(2), radix: 16)}");
  // print("GasAmount: ${BigInt.parse(gasAmountStr.substring(2), radix: 16)}");

  if (data != null) {
    params[0]["data"] = data;
  }

  // native transfer
  if (functionSignatureHash.isEmpty && amount != null) {
    params[0]["value"] = "0x${amount.toRadixString(16)}";
  }

  return params;
}

String makeBurnData(
    String functionSignatureHash, Uint8List hash, MsgSignature signature) {
  String data = functionSignatureHash +
      uint8ListTo32ByteHex(hash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0');
  return data;
}

String makeRedeemTwinTokenData(String functionSignatureHash, Uint8List hash,
    MsgSignature signature, String offerHash) {
  String data = functionSignatureHash +
      uint8ListTo32ByteHex(hash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0') +
      offerHash.substring(2).padLeft(64, '0');
  return data;
}

String makeCancelOfferData(
    String functionSignatureHash,
    EthereumAddress marketplaceContract,
    Uint8List hash,
    MsgSignature signature,
    String encodedOfferData) {
  String data = functionSignatureHash +
      marketplaceContract.toString().substring(2).padLeft(64, '0') +
      uint8ListTo32ByteHex(hash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0') +
      "00000000000000000000000000000000000000000000000000000000000000c0" +
      (encodedOfferData.substring(2).length ~/ 2)
          .toRadixString(16)
          .padLeft(64, '0') +
      encodedOfferData.substring(2);
  return data;
}

String makeRecoverTokenData(
    String functionSignatureHash, Uint8List hash, MsgSignature signature) {
  String data = functionSignatureHash +
      uint8ListTo32ByteHex(hash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0');
  return data;
}

String makeErc20TransferData(
    String functionSignatureHash, EthereumAddress to, BigInt value) {
  String data = functionSignatureHash +
      to.toString().substring(2).padLeft(64, '0') +
      value.toRadixString(16).padLeft(64, '0');
  return data;
}

String makeErc20TransferFromData(
  String functionSignatureHash,
  EthereumAddress from,
  EthereumAddress to,
  BigInt value,
) {
  String data = functionSignatureHash +
      from.toString().substring(2).padLeft(64, '0') +
      to.toString().substring(2).padLeft(64, '0') +
      value.toRadixString(16).padLeft(64, '0');
  return data;
}

String makeTransferFromData(String functionSignatureHash, Uint8List hash,
    MsgSignature signature, bool? enableRecovery) {
  final recovery = enableRecovery ?? false;
  String data = functionSignatureHash +
      uint8ListTo32ByteHex(hash) +
      signature.r.toRadixString(16).padLeft(64, '0') +
      signature.s.toRadixString(16).padLeft(64, '0') +
      signature.v.toRadixString(16).padLeft(64, '0') +
      (recovery ? "01".padLeft(64, "0") : "00".padLeft(64, "0"));
  return data;
}

String makeApproveData(
    String functionSignatureHash, BigInt tokenId, EthereumAddress to) {
  String data = functionSignatureHash +
      to.toString().substring(2).padLeft(64, '0') +
      tokenId.toRadixString(16).padLeft(64, '0');
  return data;
}

String makeOfferItemData(
    String functionSignatureHash,
    BigInt tokenId,
    EthereumAddress marketplaceContract,
    EthereumAddress sellerPayoutAddress,
    BigInt offerPrice,
    String typedDataHash) {
  String data = functionSignatureHash +
      tokenId.toRadixString(16).padLeft(64, '0') +
      marketplaceContract.toString().substring(2).padLeft(64, '0') +
      sellerPayoutAddress.toString().substring(2).padLeft(64, '0') +
      offerPrice.toRadixString(16).padLeft(64, '0') +
      typedDataHash.substring(2).padLeft(64, '0');
  return data;
}

Future<dynamic> getTwinOwner(
    String chainRpcUrl, EthereumAddress collectionId, BigInt tokenId) async {
  try {
    var owner = await queryCollectionContract(
        chainRpcUrl, collectionId, "ownerOf", [tokenId]);
    print('result: ${owner[0]}');
    return owner[0];
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getVoucherOwner(String chainRpcUrl,
    EthereumAddress voucherContractAddress, BigInt tokenId) async {
  try {
    var owner = await queryVoucherContract(
        chainRpcUrl, voucherContractAddress, "ownerOf", [tokenId]);
    return owner[0];
  } on RPCError catch (e) {
    //errorCode 3 == ERC721: invalid token ID; which means voucher token does not exist
    if (e.errorCode == 3) {
      //voucher token does not exist
      return null;
    }
    rethrow;
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    rethrow;
  }
}

Future<dynamic> getApproved(
    String chainRpcUrl, EthereumAddress collectionId, BigInt tokenId) async {
  print('checking owner of tokenId $tokenId on chain $chainRpcUrl');
  try {
    var approval = await queryCollectionContract(
        chainRpcUrl, collectionId, "getApproved", [tokenId]);
    print('result: ${approval[0]}');
    return approval[0];
  } catch (e) {
    print('Error while fetching approval of tokenId $tokenId: $e');
    return e;
  }
}

Future<bool> checkMinterRole(String chainRpcUrl,
    EthereumAddress contractAddress, EthereumAddress walletAddress) async {
  try {
    Uint8List minterRoleUint8 = keccakUtf8("MINTER_ROLE");
    List res = await queryCollectionContract(chainRpcUrl, contractAddress,
        "hasRole", [minterRoleUint8, walletAddress]);
    return res[0];
  } catch (e) {
    print('Error while checking MINTER_ROLE: $e');
    //throw Exception('Error while checking MINTER_ROLE: $e');
    return false;
  }
}

Future<String> getContractName(
    String chainRpcUrl, EthereumAddress collectionId) async {
  try {
    var name =
        await queryCollectionContract(chainRpcUrl, collectionId, "name", []);
    return name[0];
  } catch (e) {
    print('Error while fetching name of collection $collectionId: $e');
    throw Exception(
        'Error while fetching name of collection $collectionId: $e');
  }
}

Future<EthereumAddress> getVoucherContractFromTwin(
    String chainRpcUrl, EthereumAddress collectionId) async {
  try {
    var result = await queryCollectionContract(
        chainRpcUrl, collectionId, "voucherNFTCollectionAddress", []);
    return result[0];
  } catch (e) {
    print(
        'Error while fetching voucher contract address of collection $collectionId: $e');
    throw Exception(
        'Error while fetching voucher contract address of collection $collectionId: $e');
  }
}

Future<dynamic> getTokenUri(
    String chainRpcUrl, EthereumAddress collectionId, BigInt tokenId) async {
  try {
    var uri = await queryCollectionContract(
        chainRpcUrl, collectionId, "tokenURI", [tokenId]);
    return uri[0];
  } catch (e) {
    print('Error while fetching uri of tokenId $tokenId: $e');
    throw Exception('Error while fetching uri of tokenId $tokenId: $e');
  }
}

Future<EthereumAddress> getCollectionId(
    String chainRpcUrl, String registryAddress, BigInt tokenId) async {
  try {
    List collectionId = await queryRegistryContract(
        chainRpcUrl, registryAddress, "tokenRegistry", [tokenId]);
    return collectionId[0];
  } catch (e) {
    print('Error while fetching registry entry of tokenId $tokenId: $e');
    throw Exception(
        'Error while fetching registry entry of tokenId $tokenId: $e');
  }
}

Future<TransactionReceipt?> getTxnReceipt(
    String chainRpcUrl, String txnHash) async {
  final web3Client = getWeb3Client(chainRpcUrl);

  try {
    var txnReceipt = await web3Client.getTransactionReceipt(txnHash);
    while (txnReceipt == null) {
      await Future.delayed(const Duration(seconds: 2));
      txnReceipt = await web3Client.getTransactionReceipt(txnHash);
    }
    return txnReceipt;
  } catch (e) {
    print('Error while fetching txn receipt: $e');
    return null;
  }
}

Future<void> checkAndShowShippingPopup(BuildContext context, WidgetRef ref,
    {VoidCallback? setShippingPopupIsShownState}) async {
  final UserSession? userSession = ref.read(userSessionProvider);

  if (userSession == null) {
    return;
  }

  final List<Purchase> unredeemedPurchases =
      await ref.read(unredeemedVoucherNftsProvider.future);

  for (final purchase in unredeemedPurchases) {
    if (!purchase.manualHandover && purchase.shippingInfo == null) {
      await showCustomPopup(
          context,
          icon: Icon(Icons.local_shipping_outlined,
              size: 90, color: CustomColors(dotenv.get('APP_ID')).accentColor),
          context.loc.claimPhysicalItem,
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              context.loc.requestShipment,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            CustomRoundedButton(
              text: context.loc.enterShippingAddress,
              onPressed: () {
                Navigator.pushNamed(
                    context, EnterShippingAddressScreen.routeName);
              },
            ),
            const SizedBox(
              height: 10,
            ),
            CustomOutlinedButton(
              width: double.infinity,
              buttonText: context.loc.manualHandover,
              onPressed: () async {
                try {
                  await BackendToken.postManualHandoverToBackend(
                      purchase);
                  ScaffoldMessenger.of(context).showSnackBar(
                      returnSnackBarWidget(context.loc.successHeadingSnackbar,
                          context.loc.successManualHandover, 'success'));
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    returnSnackBarWidget(context.loc.errorHeadingSnackBar,
                        context.loc.pleaseTryAgainLater, 'error'),
                  );
                }
              },
            ),
          ]),
          setShippingPopupIsShownState: setShippingPopupIsShownState);
    }
  }
}

Future<EthereumAddress> getLastSellerAddress(String chainRpcUrl,
    EthereumAddress controllerContractAddress, BigInt tokenId) async {
  try {
    final List result = await queryControllerContract(chainRpcUrl,
        controllerContractAddress, "getLastSellerAddress", [tokenId]);
    print(result);
    return result[0];
  } catch (e) {
    print('Error while fetching last seller address of tokenId $tokenId: $e');
    throw Exception(
        'Error while fetching last seller address of tokenId $tokenId: $e');
  }
}
