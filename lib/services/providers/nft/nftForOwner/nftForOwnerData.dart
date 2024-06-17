import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/services/providers/common/notifierPaginationData.dart';

class OCNFTsForOwnerData
    extends NotifierPaginationData<OcOwnedNft, Map<int, String?>> {
  OCNFTsForOwnerData({
    required super.data,
    required super.loading,
    required super.page,
    required super.pageSize,
    required super.canLoadMore,
    required super.error,
  });

  factory OCNFTsForOwnerData.initial({
    int pageSize = 10,
  }) {
    return OCNFTsForOwnerData(
      data: [],
      loading: false,
      page: Map.fromEntries(
        chainConfig.keys.map(
          (k) => MapEntry(
            k,
            null,
          ),
        ),
      ),
      pageSize: pageSize,
      canLoadMore: true,
      error: false,
    );
  }

  OCNFTsForOwnerData copyWith({
    List<OcOwnedNft>? data,
    bool? loading,
    Map<int, String?>? page,
    int? pageSize,
    bool? canLoadMore,
    bool? error,
  }) {
    return OCNFTsForOwnerData(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      canLoadMore: canLoadMore ?? this.canLoadMore,
      error: error ?? this.error,
    );
  }
}
