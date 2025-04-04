import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/screens/UserScanResultsScreen.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreation.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreationService.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

class RestoreTokenPopup extends ConsumerStatefulWidget {
  const RestoreTokenPopup(
      {super.key, required this.metadata, required this.tokenId});

  final String tokenId;
  final DigitalTwinMetadata metadata;

  @override
  ConsumerState<RestoreTokenPopup> createState() => _RestoreTokenPopupState();
}

class _RestoreTokenPopupState extends ConsumerState<RestoreTokenPopup> {
  bool _isRestoring = false;

  @override
  Widget build(
    BuildContext context,
  ) {

    return Flexible(
      child: SizedBox(
        width: double.infinity,
        child: AnimatedOpacity(
          opacity: _isRestoring ? 0.5 : 1,
          duration: const Duration(milliseconds: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.loc.nftCreationRestoreTokenPopupMessage),
              const SizedBox(
                height: 16,
              ),
              ...[
                CustomOutlinedButton(
                  disabled: _isRestoring,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  buttonText:
                      context.loc.nftCreationRestoreTokenPopupCancelButton,
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomRoundedButton(
                  isLoading: _isRestoring,
                  onPressed: () async {
                    _isRestoring = true;
                    if (mounted) {
                      setState(() {});
                    }
                    final messenger = ScaffoldMessenger.of(
                      context,
                    );
                    final error =
                        await BackendCreation.restoreDigitalTwinCreation(
                      id: widget.metadata.id,
                      tokenId: widget.tokenId,
                    );
                    _isRestoring = false;
                    if (mounted) {
                      setState(() {});
                    }

                    if (error != null) {
                      messenger.showSnackBar(
                        returnSnackBarWidget(
                          context.loc.errorHeadingSnackBar,
                          error,
                          'error',
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      messenger.showSnackBar(
                        returnSnackBarWidget(
                          context.loc.successHeadingSnackbar,
                          context.loc.nftCreationRestoreTokenPopupSuccessTitle,
                          'success',
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  text: context.loc.nftCreationRestoreTokenPopupRestoreButton,
                ),
                const SizedBox(
                  height: 8,
                ),
                CustomRoundedButton(
                    text: context.loc.nftCreationRestoreTokenPopupViewTokenButton,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        UserScanResultsScreen.routeName,
                      );
                    })
              ],
            ],
          ),
        ),
      ),
    );
  }
}
