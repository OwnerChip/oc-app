import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

class WebsocketConnectionErrorPopup extends ConsumerWidget {
  const WebsocketConnectionErrorPopup({
    super.key,
    required this.parentContext,
  });

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final websocketState = ref.watch(websocketProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (websocketState.connected) {
        Future.delayed(Duration(seconds: 1)).then((_) {
          Navigator.of(context).pop();
        });
      }
    });

    return Flexible(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 16,
            ),
            if (websocketState.connecting)
              const CircularProgressIndicator()
            else if (websocketState.connected)
              Text(context.loc.reconnectWebSocketSuccessText)
            else ...[
              Text(context.loc.noConnection),
              const SizedBox(
                height: 16,
              ),
              CustomOutlinedButton(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(
                    parentContext,
                  );
                  ref.read(websocketProvider.notifier).init().then((res) {
                    messenger.showSnackBar(
                      returnSnackBarWidget(
                        res
                            ? context.loc.successHeadingSnackbar
                            : context.loc.errorHeadingSnackBar,
                        res
                            ? context.loc.reconnectWebSocketSuccessText
                            : context.loc.reconnectWebSocketErrorText,
                        res ? "success" : 'error',
                      ),
                    );
                  });
                },
                buttonText: context.loc.reconnectWebSocketButtonText,
              )
            ],
          ],
        ),
      ),
    );
  }
}
