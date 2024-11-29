import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

typedef BuildSnackBarAction = Widget Function(
  BuildContext context,
  WidgetRef ref,
  VoidCallback dismissSnackBar,
);

class CustomSnackBarContent extends ConsumerStatefulWidget {
  const CustomSnackBarContent({
    Key? key,
    required this.heading,
    required this.text,
    required this.alertType,
    required this.actionBuilder,
  }) : super(key: key);

  final String text;
  final String heading;
  final String
      alertType; //alert type can be 'success' or 'error'; different alertTypes can be added and handled in the future
  final BuildSnackBarAction? actionBuilder;

  @override
  ConsumerState<CustomSnackBarContent> createState() => _CustomSnackBarContentState();
}

class _CustomSnackBarContentState extends ConsumerState<CustomSnackBarContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: widget.alertType == 'success'
                ? CustomColors(dotenv.get('APP_ID')).successColor
                : widget.alertType == 'warning'
                    ? Colors.amber
                    : CustomColors(dotenv.get('APP_ID')).errorColor,
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: Row(
          children: [
            SizedBox(
                width: 48,
                child: Icon(
                    widget.alertType == 'success' ? Icons.check_circle : Icons.error,
                    size: 36,
                    color: Theme.of(context).cardColor)),
            Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.heading,
                        style: TextStyle(
                            fontSize: 18, color: Theme.of(context).cardColor)),
                    Flexible(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                            color: Theme.of(context).cardColor, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ]),
            ),
            if (widget.actionBuilder != null)
              widget.actionBuilder!(
                context,
                ref,
                () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
          ],
        ));
  }
}
