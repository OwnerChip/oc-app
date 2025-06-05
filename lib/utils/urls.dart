import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web3dart/web3dart.dart';

String getBecomeACreatorUrl(String? jwt) {
  return "${dotenv.get("WEB_APP_URI")}/en/signup${jwt != null ? '?jwt=$jwt' : ''}";
}

String getItemOwnerChipUrl(EthereumAddress address) {
  final itemUrl = dotenv.get("IS_INTERNAL") == "true"
      ? dotenv.get("NDEF_URL_TEST")
      : dotenv.get("NDEF_URL");

  return "${itemUrl.startsWith("https://") ? "" : "https://"}$itemUrl${itemUrl.endsWith("/") ? "" : "/"}${address.hex}";
}
