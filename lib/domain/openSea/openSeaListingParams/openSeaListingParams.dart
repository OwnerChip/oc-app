import 'package:ownerchip_whitelabel/domain/openSea/openSeaConsideration/openSeaConsideration.dart';
import 'package:ownerchip_whitelabel/domain/openSea/openSeaOffer/openSeaOffer.dart';

class OpenSeaListingParams {
  final String
      offerer; // The address which supplies all the items in the offer.
  final List<OpenSeaOffer>
      offer; // Items that may be transferred from the offerer's account.
  final List<OpenSeaConsideration>
      consideration; // Array of items which must be received by a recipient to fulfill the order. One of the consideration items must be the OpenSea marketplace fee.
  final int startTime; // blockTime
  final int endTime; // blockTime
  final String orderType; // e.g. "listing"
  final String salt; // arbitrary source of entropy
  final String zone = '0x0000000000000000000000000000000000000000';
  final String zoneHash =
      '0x0000000000000000000000000000000000000000000000000000000000000000';
  final String conduitKey =
      "0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000";
  final int
      counter; // Must match the current counter for the given offerer. https://etherscan.io/address/0x00000000000000adc04c56bf30ac9d3c0aaf14dc#readContract#F2

  OpenSeaListingParams({
    required this.offerer,
    required this.offer,
    required this.consideration,
    required this.startTime,
    required this.endTime,
    required this.orderType,
    required this.salt,
    required this.counter,
  });
}
