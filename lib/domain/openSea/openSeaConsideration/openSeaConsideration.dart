import 'package:ownerchip_whitelabel/domain/openSea/openSeaOffer/openSeaOffer.dart';

class OpenSeaConsideration extends OpenSeaOffer {
  final String
      recipient; // The address which will receive the consideration item when the order is executed.

  OpenSeaConsideration({
    required this.recipient,
    required int itemType,
    required String token,
    required int identifierOrCriteria,
    required int startAmount,
    required int endAmount,
  }) : super(
          itemType: itemType,
          token: token,
          identifierOrCriteria: identifierOrCriteria,
          startAmount: startAmount,
          endAmount: endAmount,
        );
}
