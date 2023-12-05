import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';

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
  DeployedContract contract = await getCollectionContract(collectionId);
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client(chainRpcUrl);
  List<dynamic> result = await web3Client.call(
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

Future<BigInt> estimateGas(String chainRpcUrl, EthereumAddress contractAddress,
    Uint8List txData, EthereumAddress fromAddress) async {
  final web3Client = getWeb3Client(chainRpcUrl);
  BigInt result = await web3Client.estimateGas(
      sender: fromAddress, to: contractAddress, data: txData);
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
    MsgSignature signature, String tokenURI) {
  String data = functionSignatureHash +
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
  String? gasPrice,
  BigInt? tokenId,
  bool? enableRecovery,
  EthereumAddress? sellerPayoutAddress,
}) async {
  String data;
  if (functionSignatureHash == mintFunctionSignature) {
    data = makeMintData(
        functionSignatureHash, randomValueHash, signature, tokenURI!);
  } else if (functionSignatureHash == burnFunctionSignature) {
    data = makeBurnData(functionSignatureHash, randomValueHash, signature);
  } else if (functionSignatureHash == transferFromFunctionSignature) {
    data = makeTransferFromData(
        functionSignatureHash, randomValueHash, signature, enableRecovery);
  } else if (functionSignatureHash == approveFunctionSignature) {
    data = makeApproveData(functionSignatureHash, tokenId!, toAccount!);
  } else if (functionSignatureHash == offerItemFunctionSignature) {
    //TODO: pass real params
    data = makeOfferItemData(
        functionSignatureHash,
        tokenId!,
        EthereumAddress.fromHex('0x00000000000000adc04c56bf30ac9d3c0aaf14dc'),
        sellerPayoutAddress!,
        '0x6b7a97faedb7b95a98fd5cdcc3d4b3627f276f4dd261b6db86777a0ed7d45916');
  } else {
    throw Exception('Invalid function signature hash');
  }

  String gasAmount = "0x55730"; // fallback: 300000 gas
  try {
    BigInt gasAmountEst =
        await estimateGas(chainRpcUrl, collectionId, hexToBytes(data), from!);
    gasAmount = "0x${gasAmountEst.toRadixString(16)}";
    print("ESTIMATED GAS AMOUNT: $gasAmount");
  } catch (e) {
    print("ERROR estimating gas amount: $e");
  }

  if (gasPrice == null) {
    try {
      BigInt estimatedGasPrice = await estimateGasPrice(chainRpcUrl);
      gasPrice = "0x${estimatedGasPrice.toRadixString(16)}";
      print("ESTIMATED GAS PRICE: $gasPrice");
    } catch (e) {
      print("ERROR estimating gas price: $e");
      gasPrice = dotenv.get('DEFAULT_GAS_PRICE'); // fallback
    }
  }
  gasAmount = "0x55730"; // fallback: 350000 gas
  final params = [
    {
      "from": from.toString(),
      "to": collectionId.toString(),
      "data": data,
      "gasPrice": gasPrice,
      "gas": gasAmount
    },
  ];
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

// offerItem(
//         uint256 tokenId,
//         address marketplaceContract,
//         address payable sellerPayoutAddress,
//         bytes32 typedSignatureHash
//     )

String makeOfferItemData(
    String functionSignatureHash,
    BigInt tokenId,
    EthereumAddress marketplaceContract,
    EthereumAddress sellerPayoutAddress,
    String typedSignatureHash) {
  String data = functionSignatureHash +
      tokenId.toRadixString(16).padLeft(64, '0') +
      marketplaceContract.toString().substring(2).padLeft(64, '0') +
      sellerPayoutAddress.toString().substring(2).padLeft(64, '0') +
      typedSignatureHash.substring(2).padLeft(64, '0');
  return data;
}

Future<dynamic> getOwner(
    String chainRpcUrl, EthereumAddress collectionId, BigInt tokenId) async {
  print('checking owner of tokenId $tokenId on chain $chainRpcUrl');
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

Future<dynamic> getTxnReceipt(String chainRpcUrl, String txnHash) async {
  final web3Client = getWeb3Client(chainRpcUrl);

  try {
    var txnReceipt = await web3Client.getTransactionReceipt(txnHash);
    while (txnReceipt == null) {
      txnReceipt = await web3Client.getTransactionReceipt(txnHash);
    }
    return txnReceipt;
  } catch (e) {
    print('Error while fetching txn receipt: $e');
    return e;
  }
}
