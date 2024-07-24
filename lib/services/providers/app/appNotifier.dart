import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_ios_dialog/native_ios_dialog.dart';
import 'package:ownerchip_whitelabel/domain/appVersion/appVersion.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/providers/app/appData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppNotifier extends Notifier<AppData> {
  @override
  AppData build() {
    return AppData.initial();
  }

  Future<void> showUpgrade(
    BuildContext context,
  ) async {
    state = state.copyWith(upgradeShown: true);

    Future<void> onClick() async {
      if (Platform.isIOS) {
        await launchUrl(Uri.parse(state.appDto!.appStoreLink));
      } else if (Platform.isAndroid) {
        await launchUrl(Uri.parse(state.appDto!.googlePlayLink));
      }
    }

    if (Platform.isIOS) {
      await NativeIosDialog(
        title: context.loc.newVersionTitle,
        message: context.loc.newVersionAvailable,
        actions: [
          NativeIosDialogAction(
            text: context.loc.newVersionUpdateButton,
            onPressed: () {},
            style: NativeIosDialogActionStyle.defaultStyle,
          ),
        ],
      ).show().then((_) {
        onClick();
      });
    } else {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              context.loc.newVersionTitle,

            ),
            content: Text(
              context.loc.newVersionAvailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: onClick,
                child: Text(
                  context.loc.newVersionUpdateButton,
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                    color: CustomColors(dotenv.get("APP_ID")).accentColor,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    state = state.copyWith(upgradeShown: false);
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);

    try {
      final appDto = await BackendApp.getApp();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = AppVersion.fromString(packageInfo.version);

      state = state.copyWith(
        appDto: appDto,
        upgradeRequired: appDto.minRequiredVersion > currentVersion,
      );
    } catch (e, st) {
      talker.error("Error getting app data from backend: $e", st);
      state = state.copyWith(hasError: true);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final appNotifierProvider = NotifierProvider<AppNotifier, AppData>(
  AppNotifier.new,
);
