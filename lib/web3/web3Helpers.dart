import 'package:web3dart/web3dart.dart';
import '../utils/utils.dart';
import 'package:flutter/foundation.dart';

String makeBurnTransactionData(Uint8List cardId) {
  var burnFunctionSignature = '42966c68';
  var tokenIdHex = uint8ListTo32ByteHex(cardId);
  var burnTransactionData = "0x" + burnFunctionSignature + tokenIdHex;
  return burnTransactionData;
}

dynamic makeBurnParams(String from, String to, Uint8List cardId) {
  String data = makeBurnTransactionData(cardId);
  final params = [
    {
      "from": from,
      "to": to,
      "data": data,
      "gasPrice": "0x77359400",
      "gas": "0x30D40",
    },
  ];
  return params;
}

String makeMintTransactionData(
    String receivingWalletAddress, String tokenURI, Uint8List cardId) {
  String from = receivingWalletAddress.substring(2).padLeft(64, '0');
  String tokenURILocation = "60".padLeft(64, '0');
  String tokenId = uint8ListTo32ByteHex(cardId);
  String tokenUriLength = (tokenURI.length).toRadixString(16).padLeft(64, '0');
  String tokenURIHex = stringToHex(tokenURI);
  String data = "0x" +
      "ba7aef43" +
      from +
      tokenURILocation +
      tokenId +
      tokenUriLength +
      tokenURIHex;
  return data;
}

dynamic makeMintParams(
    String from, String to, String tokenURI, Uint8List cardId) {
  String data = makeMintTransactionData(from, tokenURI, cardId);
  final params = [
    {
      "from": from,
      "to": to,
      "data": data,
      "gasPrice": "0x77359400",
      "gas": "0x30D40",
    },
  ];
  return params;
}

// dynamic makeMintTransaction(String from, String to,
//     String tokenURI, Uint8List cardId) {
//   String data = makeMintTransactionData(from, tokenURI, cardId);
//   final customRequest = {
//     "id": 1,
//     "jsonrpc": "2.0",
//     "method": "eth_call",
//     "params": [
//       {
//         "from": from,
//         "to": to,
//         "data": data,
//         "gasPrice": "0x64",
//         "gas": "0x30D40",
//       },
//     ],
//   };
//   return customRequest;
// }
