import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:web3dart/crypto.dart';

class MsgSignatureJsonConverter
    extends JsonConverter<MsgSignature, Map<dynamic, dynamic>> {
  const MsgSignatureJsonConverter();

  @override
  MsgSignature fromJson(Map json) {
    return msgSignatureFromJson(Map.fromEntries(json.entries.map(
      (e) => MapEntry(
        e.key.toString(),
        e.value,
      ),
    )));
  }

  @override
  Map toJson(MsgSignature object) {
    return msgSignatureToJson(object);
  }
}
