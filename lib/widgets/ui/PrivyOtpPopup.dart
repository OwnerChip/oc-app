import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class PrivyOtpPopup extends StatefulWidget {
  final String email;

  const PrivyOtpPopup({super.key, required this.email});

  @override
  State<PrivyOtpPopup> createState() => _PrivyOtpPopupState();
}

class _PrivyOtpPopupState extends State<PrivyOtpPopup> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20.0))),
      title: Text(
        context.loc.loginWithEmail_otpTitle,
        textAlign: TextAlign.center,
      ),
      titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
          fontWeight: CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.loc.loginWithEmail_cancelButton,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _otpController.text.trim());
          },
          child: Text(
            context.loc.loginWithEmail_okButton,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.loc.loginWithEmail_otpSubtitle(widget.email),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return context.loc.loginWithEmail_otpEmptyError;
                if (v.trim().length != 6) return context.loc.loginWithEmail_otpLengthError;
                return null;
              },
              decoration: InputDecoration(hintText: context.loc.loginWithEmail_otpHint),
            ),
          ],
        ),
      ),
    );
  }
}

