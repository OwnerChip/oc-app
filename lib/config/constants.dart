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
const String cancelMarketplaceOfferSignature = '0x7a616970';

//redeemItem
const String redeemItemFunctionSignature = '0x1247fcb5';

//recoverToken
const String recoverTokenFunctionSignature = '0x41b49312';

// erc20 approve
const String erc20ApproveFunctionSignature = '0x095ea7b3';

// erc20 transfer
const String erc20TransferFunctionSignature = '0xa9059cbb';

// erc20 transferFrom
const String erc20TransferFromFunctionSignature = '0x23b872dd';
