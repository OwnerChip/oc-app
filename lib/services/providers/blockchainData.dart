import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/backend.services.dart';

//flutter futureprovider that calls getEthPrice()

final ethPriceProvider =
    FutureProvider.autoDispose.family<Map, String>((ref, cryptoSymbol) async {
  final Map ethPrice = await getEthPrice(cryptoSymbol);
  return ethPrice;
});
