import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;

import 'app_localizations.dart';

/// Notifier that provides AppLocalizations and updates on locale change.
class _AppLocalizationsNotifier extends Notifier<AppLocalizations> {
  @override
  AppLocalizations build() {
    ref.keepAlive();
    final observer = _LocaleObserver((locales) {
      state = lookupAppLocalizations(ui.window.locale);
    });
    final binding = WidgetsBinding.instance;
    binding.addObserver(observer);
    ref.onDispose(() => binding.removeObserver(observer));
    return lookupAppLocalizations(ui.window.locale);
  }
}

/// provider used to access the AppLocalizations object for the current locale
final appLocalizationsProvider =
    NotifierProvider<_AppLocalizationsNotifier, AppLocalizations>(
        _AppLocalizationsNotifier.new);

/// observed used to notify the caller when the locale changes
class _LocaleObserver extends WidgetsBindingObserver {
  _LocaleObserver(this._didChangeLocales);
  final void Function(List<Locale>? locales) _didChangeLocales;
  @override
  void didChangeLocales(List<Locale>? locales) {
    _didChangeLocales(locales);
  }
}
