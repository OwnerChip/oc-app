import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:ownerchip_whitelabel/screens/DeepLinkLoginConfirmScreen.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';

class AppLinksService {
  AppLinksService._();

  static final AppLinksService instance = AppLinksService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Call once from [_MyApp.initState] after the widget tree is mounted.
  void init() {
    // Handle deep links while the app is already running (foreground / background).
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e, st) {
        talker.error('AppLinksService: stream error', e, st);
      },
    );

    // Handle the deep link that cold-started the app.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    }).catchError((e, st) {
      talker.error('AppLinksService: getInitialLink error', e, st);
    });
  }

  void _handleUri(Uri uri) {
    talker.info('AppLinksService: received uri=$uri');

    if (uri.scheme == 'ownerchip' && uri.host == 'login') {
      final requestIdStr = uri.queryParameters['requestId'];
      final requestId = int.tryParse(requestIdStr ?? '');

      if (requestId == null) {
        talker.warning(
          'AppLinksService: invalid or missing requestId in $uri',
        );
        return;
      }

      final context = navigatorKey.currentContext;
      if (context == null) {
        talker.warning('AppLinksService: navigatorKey has no context yet');
        return;
      }

      showDeepLinkLoginConfirmPopup(context, requestId);
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

