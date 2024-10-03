import 'package:flutter_dotenv/flutter_dotenv.dart';

String getBecomeACreatorUrl(String? jwt) {
  return "${dotenv.get("WEB_APP_URI")}/en/signup${jwt != null ? '?jwt=$jwt' : ''}";
}
