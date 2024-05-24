

import 'package:json_annotation/json_annotation.dart';
import 'package:ownerchip_whitelabel/domain/walletType/eWalletType.dart';

/*
 Need this converter to convert [EWalletType] to int and vice versa
 because initially it was serialized as index
 To keep the backward compatibility, we need this converter
 */
class EWalletTypeJsonConverter implements JsonConverter<EWalletType, int> {
  const EWalletTypeJsonConverter();

  @override
  EWalletType fromJson(int json) {
    return EWalletType.values[json];
  }

  @override
  int toJson(EWalletType object) {
    return object.index;
  }
}