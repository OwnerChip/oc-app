import 'package:web3dart/web3dart.dart';

final EthereumAddress zeroAddress =
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

//mint function signatures
const String mintFunctionSignature = '0xcb5a7173';

//burn function signatures
const String burnFunctionSignature = '0x469fd767';

// transfer(address,bytes32,bytes32,bytes32,uint8)
const String transferFromFunctionSignature = '0x8f10e951';

// approve
const String approveFunctionSignature = '0x095ea7b3';

//offerItem
const String offerItemFunctionSignature = '0xfbdba33a';

//cancelItem
const String cancelItemFunctionSignature = '0x89e2f42c';

//redeemItem
const String redeemItemFunctionSignature = '0x1247fcb5';
