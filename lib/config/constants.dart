import 'package:web3dart/web3dart.dart';

final EthereumAddress zeroAddress =
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

//mint function signatures
const String mintFunctionSignature = '0xcb5a7173';
const String mintVoucherFunctionSignature = '0xa4bf45e8';

//burn function signatures
const String burnFunctionSignature = '0x469fd767';

// transfer(address,bytes32,bytes32,bytes32,uint8)
const String transferFromFunctionSignature = '0x8f10e951';

// approve
const String approveFunctionSignature = '0x095ea7b3';

//offerItem
const String offerItemFunctionSignature = '0xc8f1044d';

//cancelOffer
const String cancelOfferFunctionSignature = '0x32864096';

//redeemItem
const String redeemItemFunctionSignature = '0x1247fcb5';

//recoverToken
const String recoverTokenFunctionSignature = '0x41b49312';
