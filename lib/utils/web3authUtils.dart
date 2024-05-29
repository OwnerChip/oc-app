import 'package:sentry_flutter/sentry_flutter.dart';
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
    Exception? lastException;
    StackTrace? lastStackTrace;

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
      } on Exception catch (e, st) {
        lastException = e;
        lastStackTrace = st;
        await Future.delayed(
          delay,
        );
      }
    }

    Sentry.captureException(
      lastException!,
      stackTrace: lastStackTrace,
    );

    if (returnLastIfFailed) {
      return _lastSignResult;
    }

    return null;
  }
}
