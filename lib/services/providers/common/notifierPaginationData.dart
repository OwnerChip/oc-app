class NotifierPaginationData<TD, TP> {
  final List<TD> data;
  final bool loading;
  final TP page;
  final int pageSize;
  final bool canLoadMore;
  final bool error;

  const NotifierPaginationData({
    required this.data,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.canLoadMore,
    required this.error,
  });


}
