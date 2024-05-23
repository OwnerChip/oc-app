class OpenSeaOffer {
  final int itemType;
  final String token; // Contract address
  final int identifierOrCriteria;
  final int startAmount;
  final int endAmount; // usually the start amount

  OpenSeaOffer({
    required this.itemType,
    required this.token,
    required this.identifierOrCriteria,
    required this.startAmount,
    required this.endAmount,
  });
}
