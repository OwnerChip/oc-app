import 'package:web3dart/web3dart.dart';

final EthereumAddress zeroAddress =
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

//mint function signatures
const String mintFunctionSignature = '0xcb5a7173';
const String gaslessMintFunctionSignature = '0xcb5a7173';

//burn function signatures
const String burnFunctionSignature = '0x469fd767';
const String gaslessBurnFunctionSignature = '0x469fd767';

//transfer function signatures

// transfer(address,bytes32,bytes32,bytes32,uint8)
const String transferFunctionSignature = '0xf96394cf';

// gaslessTransfer(address,bytes32,bytes32,bytes32,uint8)
const String gaslessTransferFunctionSignature = '0xf96394cf';

// approve
const String approveFunctionSignature = '0x095ea7b3';

// transferToCard
const String transferToCardFunctionSignature = '0x4a59adff';
