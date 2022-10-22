class ScanScreenArguments {
  final String nextRoute;
  ScanScreenArguments(this.nextRoute);
}

class ScanResultsScreenArguments {
  final String nftOwner;
  final bool chipIsInitialized;

  ScanResultsScreenArguments(this.nftOwner, this.chipIsInitialized);
}
