import 'package:json_annotation/json_annotation.dart';
import 'package:web3dart/web3dart.dart';

class EthereumAddressNullsafetyJsonConverter
    implements JsonConverter<EthereumAddress?, String?> {
  const EthereumAddressNullsafetyJsonConverter();

  @override
  EthereumAddress? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    return EthereumAddress.fromHex(json);
  }

  @override
  String? toJson(EthereumAddress? object) {
    return object?.hex;
  }
}
