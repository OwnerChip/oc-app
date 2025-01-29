
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

final talker = Talker(
  settings: TalkerSettings(
    /// You can enable/disable all talker processes with this field
    enabled: true,

    /// You can enable/disable saving logs data in history
    useHistory: true,

    /// Length of history that saving logs data
    maxHistoryItems: 100,

    /// You can enable/disable console logs
    useConsoleLogs: true,
    colors: {
      'error': AnsiPen()..red(),
      'critical': AnsiPen()..yellow(),
      'info': AnsiPen()..white(),
      'debug': AnsiPen()..gray(),
      'verbose': AnsiPen()..red(),
      'warning': AnsiPen()..red(),
    }
  ),

  /// Setup your implementation of logger
  logger: TalkerLogger(),

  ///etc...
);

extension TalkerDioLoggerExtension on TalkerDioLogger {
  static TalkerDioLogger instance = TalkerDioLogger(
    talker: talker,
    settings: TalkerDioLoggerSettings(
      errorPen: AnsiPen()..red,
      requestPen: AnsiPen()..green,
      responsePen: AnsiPen()..blue,
      printRequestData: true,
      printResponseData: true,
    ),
  );
}
