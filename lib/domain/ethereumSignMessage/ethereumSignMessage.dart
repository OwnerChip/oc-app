import 'package:ownerchip_whitelabel/domain/wcSignType/wcSignType.dart';

class EthereumSignMessage {
  final String data;
  final String address;
  final WCSignType type;

  const EthereumSignMessage({
    required this.data,
    required this.address,
    required this.type,
  });
}
