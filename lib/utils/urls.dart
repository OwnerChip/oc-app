import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';

String getItemOwnerChipUrl(EthereumAddress address) {
  final itemUrl = dotenv.get("IS_INTERNAL") == "true"
      ? dotenv.get("NDEF_URL_TEST")
      : dotenv.get("NDEF_URL");

  return "${itemUrl.startsWith("https://") ? "" : "https://"}$itemUrl${itemUrl.endsWith("/") ? "" : "/"}${address.hex}";
}
