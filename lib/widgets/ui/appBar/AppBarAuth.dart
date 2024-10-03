import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/AppBarAuthDropDown.dart';
import 'package:reown_appkit/reown_appkit.dart';

class AppBarAuth extends ConsumerStatefulWidget {
  const AppBarAuth({super.key});

  @override
  ConsumerState<AppBarAuth> createState() => _AppBarAuthState();
}

class _AppBarAuthState extends ConsumerState<AppBarAuth> {
  OverlayEntry? _overlayEntry;

  void _createOverlay(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AppBarAuthDropDown(
          closeOverlay: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    ReownAppKitModal? wc = ref.watch(w3mServiceProvider);
    ReownAppKitModalSession? wcSession = ref.watch(wcSessionProvider);
    UserSession? userSession = ref.watch(userSessionProvider);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        userSession != null
            ? IconButton(
                padding: const EdgeInsets.all(0.0),
                icon: Icon(Icons.account_circle_outlined,
                    color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                    size: 35),
                color: CustomColors(dotenv.get('APP_ID')).black,
                onPressed: () {
                  _createOverlay(context);
                },
              )
            : IconButton(
                padding: const EdgeInsets.all(0.0),
                icon: Icon(Icons.wallet,
                    color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                    size: 35),
                color: CustomColors(dotenv.get('APP_ID')).black,
                onPressed: () async {
                  walletPopupBuilder(context, ref);
                },
              ),
        Align(
          alignment: const Alignment(0.0, 0.95),
          child: Text(
            userSession != null
                ? context.loc.appBarProfileTitle
                : context.loc.connect,
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
