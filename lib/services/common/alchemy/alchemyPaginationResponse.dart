class AlchemyPaginationResponse<T> {
  final String? pageKey;
  final List<T> data;

  bool get canLoadMore => pageKey != null;

  const AlchemyPaginationResponse({
    this.pageKey,
    required this.data,
  });
}
