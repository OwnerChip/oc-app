import 'package:json_annotation/json_annotation.dart';
import 'package:web3dart/web3dart.dart';

class EthereumAddressJsonConverter
    implements JsonConverter<EthereumAddress, String> {
  const EthereumAddressJsonConverter();

  @override
  EthereumAddress fromJson(String json) {
    return EthereumAddress.fromHex(json);
  }

  @override
  String toJson(EthereumAddress object) {
    return object.hex;
  }
}
