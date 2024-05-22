import 'package:web3auth_flutter/web3auth_flutter.dart';

extension Web3AuthUtils on Web3AuthFlutter {
  static String? _lastSignResult;

  /*
  * This method will return the sign result from the web3auth sdk.
  * For some reason the sdk is not returning the sign result in the first attempt.
  * Sometime it throws an error that user has not logged in yet.
   */
  static Future<String?> getSignResult({
    int maxRetries = 10,
    Duration delay = const Duration(seconds: 2),
    bool checkIfIdenticalToLastResult = true,
    bool returnLastIfFailed = true,
  }) async {
    for (int i = 0; i <= maxRetries; i++) {
      try {
        final response = await Web3AuthFlutter.getSignResponse();

        if (response.success) {
          if (checkIfIdenticalToLastResult &&
              response.result == _lastSignResult) {
            continue;
          }

          _lastSignResult = response.result;

          return response.result!;
        }
      } catch (e) {
        await Future.delayed(
          delay,
        );
      }
    }

    if (returnLastIfFailed) {
      return _lastSignResult;
    }

    return null;
  }
}
