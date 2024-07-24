import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/blockchain_token.dart';
import 'package:ownerchip_whitelabel/domain/web3MarketplaceApi.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

// EIP712Domain is the domain definition used by the EIP712 standard. It is used to define the domain of the signature.
final EIP712Domain = [
  {'name': 'name', 'type': 'string'},
  {'name': 'version', 'type': 'string'},
  {'name': 'verifyingContract', 'type': 'address'},
];

// ForwardRequest is the structure of the data that is being signed. It is used to define the data to be signed.
final ForwardRequest = [
  {'name': 'info', 'type': 'string'},
  {'name': 'from', 'type': 'address'},
  {'name': 'to', 'type': 'address'},
  {'name': 'value', 'type': 'uint256'},
  {'name': 'gas', 'type': 'uint256'},
  {'name': 'nonce', 'type': 'uint256'},
  {'name': 'data', 'type': 'bytes'},
];

// This function returns the EIP712 domain used for signing a meta-transaction.
// It takes the chain ID as input and returns a map of the domain data.
Map<String, dynamic> getMetaTxTypeData(int chainId) {
  final String verifyingContract = chainConfig[chainId]!.forwarderContract!;
  return {
    'types': {
      'EIP712Domain': EIP712Domain,
      'ForwardRequest': ForwardRequest,
    },
    'domain': {
      'name': 'MinimalForwarder',
      'version': '0.0.2',
      'verifyingContract': verifyingContract,
    },
    'primaryType': 'ForwardRequest',
  };
}

// This function returns the request to be signed for a meta-transaction.
Future<Map<String, dynamic>> buildTypedV4Request(
  String functionSignatureHash,
  String chainRpcUrl,
  int chainId,
  Uint8List randomValueHash,
  MsgSignature signature,
  EthereumAddress from,
  EthereumAddress to,
  EthereumAddress? toAccount,
  String? tokenURI,
  String? voucherTokenURI,
  BigInt? tokenId,
  bool? enableRecovery,
  EthereumAddress? sellerPayoutAddress,
  BigInt? salt,
  int? endTimestamp,
  BigInt? price,
  String? encodedOfferData,
  String? typedDataHash,
  String? offerHash, {
  BlockchainToken? token,
  BigInt? amount,
  BigInt? gas,
}) async {
  final String verifyingContract = chainConfig[chainId]!.forwarderContract!;
  final String data;
  if (functionSignatureHash == mintFunctionSignature) {
    data = makeMintData(
        functionSignatureHash, randomValueHash, signature, tokenURI!, null);
  } else if (functionSignatureHash == erc20TransferFromFunctionSignature) {
    data = makeErc20TransferFromData(
      functionSignatureHash,
      from,
      toAccount!,
      amount!,
    );
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
        price!,
        typedDataHash!);
  } else if (functionSignatureHash == offerItemErc20FunctionSignature) {
    data = makeOfferItemErc20Data(
        functionSignatureHash,
        tokenId!,
        EthereumAddress.fromHex(raribleTransferProxies[chainId]!),
        sellerPayoutAddress!,
        price!,
        token?.contractAddress,
        typedDataHash!);
  } else if (functionSignatureHash == cancelMarketplaceOfferSignature) {
    data = makeCancelOfferData(
        functionSignatureHash,
        EthereumAddress.fromHex(raribleExchangeV2Contracts[chainId]!),
        randomValueHash,
        signature,
        encodedOfferData!);
  } else if (functionSignatureHash == redeemItemFunctionSignature) {
    data = makeRedeemTwinTokenData(
        functionSignatureHash, randomValueHash, signature, offerHash!);
  } else if (functionSignatureHash == recoverTokenFunctionSignature) {
    data =
        makeRecoverTokenData(functionSignatureHash, randomValueHash, signature);
  } else {
    throw Exception('Invalid function signature hash');
  }
  final BigInt nonce = await getNonce(chainRpcUrl, verifyingContract, from.hex);
  return {
    'info':
        'Please sign this message, so OwnerChip can send this transaction on your behalf.',
    'from': from.hex,
    'to': to.hex,
    'value': 0,
    'gas': gas?.toInt() ?? 500000,
    //gas actually used by mint or burn TX is approx. 200k; this can stay hard coded
    'nonce': nonce.toInt(),
    'data': data,
  };
}

// This method creates a typedData object with the specified chainId and
// request data. The result is used as the data for a MetaTransaction.

Future<Map<String, dynamic>> buildTypedData(int chainId, request) async {
  final typeData = getMetaTxTypeData(chainId);
  return {...typeData, 'message': request};
}

Future<bool> verifyGaslessTransaction(
    Map<String, dynamic> req, {
      required int chainId,
      required String signature,
    }) async {
  final client = getWeb3Client(chainConfig[chainId]!.rpcUrl);

  final contract = await getForwarderContract(
      chainConfig[chainId]!.forwarderContract.toString());

  // Convert the req map to a list of its components
  final reqParams = [
    req['info'],
    EthereumAddress.fromHex(req['from']),
    EthereumAddress.fromHex(req['to']),
    BigInt.from(req['value']),
    BigInt.from(req['gas']),
    BigInt.from(req['nonce']),
    hexToBytes(req['data']),
  ];

  final res = await client
      .call(contract: contract, function: contract.function('verify'), params: [
    reqParams,
    hexToBytes(signature), // Convert hex signature to bytes
  ]);

  return res[0] as bool;
}

// Builds a typed V4 request, which is used to build a typed data object
// which is then signed by the user's wallet to create a signature.
// This request is then passed to the smart contract as a gasless transaction.

Future<List<Map<String, dynamic>>> makeGaslessParams({
  required String functionSignatureHash,
  required String chainRpcUrl,
  required int chainId,
  required Uint8List randomValueHash,
  required MsgSignature signature,
  required EthereumAddress from,
  required EthereumAddress to,
  EthereumAddress? toAccount,
  String? tokenURI,
  String? voucherTokenURI,
  BigInt? tokenId,
  bool? enableRecovery,
  EthereumAddress? sellerPayoutAddress,
  BigInt? salt,
  int? endTimestamp,
  BigInt? price,
  String? encodedOfferData,
  String? typedDataHash,
  String? offerHash,
  BigInt? amount,
  BigInt? gas,
  BlockchainToken? token,
}) async {
  final request = await buildTypedV4Request(
    functionSignatureHash,
    chainRpcUrl,
    chainId,
    randomValueHash,
    signature,
    from,
    to,
    toAccount,
    tokenURI,
    voucherTokenURI,
    tokenId,
    enableRecovery,
    sellerPayoutAddress,
    salt,
    endTimestamp,
    price,
    encodedOfferData,
    typedDataHash,
    offerHash,
    amount: amount,
    gas: gas,
    token: token,
  );
  final typedData = await buildTypedData(chainId, request);
  return [typedData, request];
}
