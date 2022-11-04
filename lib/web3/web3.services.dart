import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/utils.dart';

Web3Client getWeb3Client() {
  var rpcUrl = dotenv.get('CHAIN_RPC');
  var client = Web3Client(rpcUrl, Client());
  return client;
}

Future<DeployedContract> getContract() async {
  String abi =
      await rootBundle.loadString("assets/contracts/contract.abi.json");
  DeployedContract contract = DeployedContract(
    ContractAbi.fromJson(abi, dotenv.get('CONTRACT_NAME')),
    EthereumAddress.fromHex(dotenv.get('CONTRACT_ADDRESS')),
  );
  return contract;
}

Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
  DeployedContract contract = await getContract();
  ContractFunction function = contract.function(functionName);
  final web3Client = getWeb3Client();
  List<dynamic> result = await web3Client.call(
      contract: contract, function: function, params: args);
  return result;
}

Future<bool> verifyToken(Uint8List tokenId, Uint8List signature) async {
  try {
    var result = await query("verifyToken", [tokenId, signature]);
    return result[0];
  } catch (e) {
    return false;
  }
}

String makeBurnTransactionData(Uint8List cardId) {
  var burnFunctionSignature = '42966c68';
  var tokenIdHex = uint8ListTo32ByteHex(cardId);
  var burnTransactionData = "0x" + burnFunctionSignature + tokenIdHex;
  return burnTransactionData;
}

dynamic makeBurnParams(String from, String to, Uint8List cardId,
    {String? gasPrice}) {
  String data = makeBurnTransactionData(cardId);
  final params = [
    {
      "from": from,
      "to": to,
      "data": data,
      "gasPrice": gasPrice ?? dotenv.get('DEFAULT_GAS_PRICE'),
      "gas": "0x30D40",
    },
  ];
  return params;
}

String makeMintTransactionData(String tokenURI, Uint8List signature) {
  String tokenUriLength = (tokenURI.length).toRadixString(16).padLeft(64, '0');
  String tokenURIHex = stringToHex(tokenURI);
  String signatureHex = String.fromCharCodes(signature);
  String data = "0x" +
      "ba7aef43" +
      "60".padLeft(64, '0') +
      tokenUriLength +
      tokenURIHex +
      signatureHex;
  return data;
}

dynamic makeMintParams(
    String from, String to, String tokenURI, Uint8List signature,
    {String? gasPrice}) {
  String data = makeMintTransactionData(tokenURI, signature);
  final params = [
    {
      "from": from,
      "to": to,
      "data": data,
      "gasPrice": gasPrice ?? dotenv.get('DEFAULT_GAS_PRICE'),
      "gas": "0x30D40",
    },
  ];
  return params;
}

Future<dynamic> getOwner(BigInt tokenId) async {
  try {
    var owner = await query("ownerOf", [tokenId]);
    print(owner);
    return owner[0];
  } catch (e) {
    print('Error while fetching owner of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getTokenUri(BigInt tokenId) async {
  try {
    var uri = await query("tokenURI", [tokenId]);
    print(uri);
    return uri[0];
  } catch (e) {
    print('Error while fetching uri of tokenId $tokenId: $e');
    return e;
  }
}

Future<dynamic> getTxnReceipt(String txnHash) async {
  final web3Client = getWeb3Client();

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
