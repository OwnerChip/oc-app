import 'package:ownerchip_whitelabel/domain/collection/collection.dart';

class BlockchainCollectionList {
  final Map<int, List<Collection>> collections;
  bool? hasAnyMinterRole;

  BlockchainCollectionList(this.collections, {this.hasAnyMinterRole});
}
