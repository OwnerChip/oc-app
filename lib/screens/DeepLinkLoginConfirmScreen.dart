import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

/// Opens the "Confirm Web Login" popup.
Future<void> showDeepLinkLoginConfirmPopup(
  BuildContext context,
  int requestId,
) {
  return showCustomPopup(
    context,
    context.loc.deepLinkLoginConfirmTitle,
    _DeepLinkLoginConfirmContent(requestId: requestId),
    icon: Icon(
      Icons.laptop_mac,
      size: 56,
      color: CustomColors(dotenv.get('APP_ID')).primaryColor,
    ),
    showCloseButton: true,
  );
}

class _DeepLinkLoginConfirmContent extends ConsumerStatefulWidget {
  const _DeepLinkLoginConfirmContent({required this.requestId});
  final int requestId;

  @override
  ConsumerState<_DeepLinkLoginConfirmContent> createState() =>
      _DeepLinkLoginConfirmContentState();
}

class _DeepLinkLoginConfirmContentState
    extends ConsumerState<_DeepLinkLoginConfirmContent> {
  bool _loading = false;
  String? _error;

  bool get _isLoggedIn => ref.read(userSessionProvider) != null;

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = ref.read(userSessionProvider);
      if (session == null) {
        setState(() => _error = context.loc.deepLinkLoginNotLoggedInError);
        return;
      }

      final sessionId = session.sessionId;
      final socketId = ref.read(websocketProvider).socket?.id ?? '';

      talker.info(
        'DeepLinkLoginConfirm: confirming requestId=${widget.requestId} '
        'sessionId=$sessionId socketId=$socketId',
      );

      final success = await BackendAuth.confirmQrCodeLogin(
        requestId: widget.requestId.toString(),
        sessionId: sessionId,
        socketId: socketId,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          returnSnackBarWidget(
            context.loc.successHeadingSnackbar,
            context.loc.deepLinkLoginSuccessMessage,
            'success',
          ),
        );
      } else {
        setState(() => _error = context.loc.deepLinkLoginConfirmError);
      }
    } catch (e, st) {
      talker.error('DeepLinkLoginConfirm._confirm', e, st);
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop(); // close the deep-link popup first
    walletPopupBuilder(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = CustomColors(dotenv.get('APP_ID')).errorColor;

    // ── Not logged in ──────────────────────────────────────────────────────
    if (!_isLoggedIn) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.loc.deepLinkLoginNotLoggedInError,
            style: theme.textTheme.bodyMedium!.copyWith(color: errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          CustomRoundedButton(
            text: context.loc.deepLinkLoginLogInNowButton,
            onPressed: _goToLogin,
          ),
        ],
      );
    }

    // ── Logged in ──────────────────────────────────────────────────────────
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.loc.deepLinkLoginConfirmDescription,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium!.copyWith(color: errorColor),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        CustomRoundedButton(
          text: context.loc.deepLinkLoginConfirmButton,
          isLoading: _loading,
          onPressed: _loading ? null : _confirm,
        ),
        const SizedBox(height: 10),
        CustomOutlinedButton(
          buttonText: context.loc.cancel,
          width: double.infinity,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}


