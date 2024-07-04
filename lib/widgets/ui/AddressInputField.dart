import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/services/qrCode.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/stylingWidgets/CustomInputDecoration.dart';
import 'package:web3dart/web3dart.dart';

class AddressInputField extends StatefulWidget {
  const AddressInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.errorText = "",
  });

  final TextEditingController controller;

  final FocusNode focusNode;

  final String errorText;

  @override
  State<AddressInputField> createState() => _AddressInputFieldState();
}

class _AddressInputFieldState extends State<AddressInputField> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              TextFormField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofocus: false,
                validator: (value) {
                  if (widget.focusNode.hasFocus) {
                    return null;
                  }

                  if (value == null || value.isEmpty) {
                    return widget.errorText;
                  }
                  try {
                    EthereumAddress.fromHex(value);
                  } catch (e) {
                    return widget.errorText;
                  }
                  return null;
                },
                decoration: customInputDecoration(
                  context,
                  context.loc.myBalanceReceivingWalletAddress,
                ).copyWith(
                  contentPadding: const EdgeInsets.only(
                    right: 96,
                    left: 12,
                  ),
                ),
                onChanged: (value) {
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              Positioned(
                right: 48,
                top: 12,
                bottom: 0,
                child: InkWell(
                  onTap: () {
                    Clipboard.getData('text/plain').then((value) {
                      if (value != null) {
                        widget.controller.text = value.text ?? '';
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    });
                  },
                  child: Text(context.loc.myBalanceWithdrawPasteAddressButton),
                ),
              ),
              Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () {
                      scanWalletQRCode(context).then((value) {
                        if (value != null) {
                          widget.controller.text = value.hex;
                          if (mounted) {
                            setState(() {});
                          }
                        }
                      });
                    },
                    child: Icon(
                      Icons.qr_code_scanner_outlined,
                      color: CustomColors(
                        dotenv.get('APP_ID'),
                      ).primaryColor,
                    ),
                  ))
            ],
          ),
        ),
      ],
    );
  }
}
