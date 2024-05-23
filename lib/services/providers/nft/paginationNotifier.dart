abstract class IPaginationNotifier {
  Future<void> refreshPage();

  Future<void> loadNextPage();
}
