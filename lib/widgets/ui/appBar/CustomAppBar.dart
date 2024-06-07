// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers/web3auth/web3authNotifier.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/AppBarAuth.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import '../../../utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:web3modal_flutter/web3modal_flutter.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  static const double kCustomAppBarHeight = 110.0;

  const CustomAppBar({
    super.key,
    this.text,
    this.showBackButton = true,
    this.showWalletButton = true,
    this.overrideBackButton,
  });

  final String? text;
  final VoidCallback? overrideBackButton;
  final bool showBackButton;
  final bool showWalletButton;

  //necessary to use because flutter?!
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: !showBackButton ? 120 : null,
      toolbarHeight: kCustomAppBarHeight,
      //only change leading width if logo is shown
      leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: showBackButton
              ? Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(0.0),
                      icon: SvgPicture.asset(
                          "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/back.svg"),
                      color: CustomColors(dotenv.get('APP_ID')).black,
                      onPressed: () {
                        if(overrideBackButton != null) {
                          overrideBackButton!();
                          return;
                        }

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )
              : Image.asset(
                  '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo_appbar.png',
                  fit: BoxFit.contain)),
      title: Text(text ?? '', style: Theme.of(context).textTheme.displaySmall),
      centerTitle: true,
      actions: [
        if (showWalletButton)
          const Padding(
            padding: EdgeInsets.only(right: 5),
            child: AppBarAuth(),
          )
      ],
      titleTextStyle: Theme.of(context).textTheme.displaySmall,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}
