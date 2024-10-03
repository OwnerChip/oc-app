import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/screens/creations/CreationsPage.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';

class CreationsNotifier extends Notifier<CreationsData> {
  @override
  CreationsData build() {
    return CreationsData.initial();
  }

  Future<void> onLogout() async {
    state = CreationsData.initial();
  }

  Future<void> navigateConditionally(
    BuildContext context,
    String? notificationUserWalletAddress, {
    bool isFromNotification = false,
  }) async {
    final session = ref.read(userSessionProvider);

    if (isFromNotification &&
        (session == null ||
            (notificationUserWalletAddress != null &&
                session.userWalletAddress.hex.toLowerCase() !=
                    notificationUserWalletAddress.toLowerCase()))) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,

          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Text(
            session == null
                ? context.loc.nftCreationsNotLoggedInTitle
                : context.loc.nftCreationsLoggedInWithDifferentWalletTitle,
            textAlign: TextAlign.center,
          ),
          titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize:
                    CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
                fontWeight:
                    CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight,
              ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session == null
                    ? context.loc.nftCreationsNotLoggedInDescription
                    : context
                        .loc.nftCreationsLoggedInWithDifferentWalletDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                  session == null
                      ? context.loc.nftCreationsNotLoggedInButton
                      : context
                          .loc.nftCreationsLoggedInWidthDifferentWalletButton,
                  style: Theme.of(context).textTheme.bodyMedium!),
            ),
          ],
        ),
      );
      return;
    }

    if (state.data != null && state.data!.isNotEmpty) {
      if(Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      Navigator.of(context).pushNamed(CreationsPage.routeName);
    }
  }

  Future<void> load({int page = 1}) async {
    state = state.copyWith(loading: true);

    try {
      // Fetch data from backend
      final data = await BackendCreation.getMyDigitalTwins(
        page,
        limit: 10,
        status: [
          DigitalTwinCreationMetadataStatus.pending,
          DigitalTwinCreationMetadataStatus.toBeBurned,
          DigitalTwinCreationMetadataStatus.toBeTransferred,
        ],
      );

      state = state.copyWith(
        data: page == 1
            ? data?.data ?? []
            : [
                ...(state.data ?? []),
                ...(data?.data ?? []),
              ],
        page: page,
        totalPages: data?.totalPages ?? 1,
        total: data?.total ?? 0,
        loading: false,
        initialized: true,
      );
    } catch (e) {
      state = state.copyWith(error: true, loading: false);
    }
  }
}

final creationsNotifierProvider =
    NotifierProvider<CreationsNotifier, CreationsData>(
  CreationsNotifier.new,
);
