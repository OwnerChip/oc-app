import 'package:web3dart/web3dart.dart';

final EthereumAddress zeroAddress =
    EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

//mint function signatures
const String mintFunctionSignature = '0xcb5a7173';
const String gaslessMintFunctionSignature = '0x7a7f274d';

//burn function signatures
const String burnFunctionSignature = '0x469fd767';
const String gaslessBurnFunctionSignature = '0xd6fc7cef';
