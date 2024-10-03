import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/fontSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class EmailLoginPopup extends StatefulWidget {
  const EmailLoginPopup({super.key});

  @override
  State<EmailLoginPopup> createState() => _EmailLoginPopupState();
}

class _EmailLoginPopupState extends State<EmailLoginPopup> {
  final TextEditingController _emailController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Form(
        key: _formKey,
        child: AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0))),
          title: Text(
            context.loc.loginWithEmail_EnterEmailText,
            textAlign: TextAlign.center,
          ),
          titleTextStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: CustomFonts(dotenv.get('APP_ID')).metadataNameFontSize,
              fontWeight:
                  CustomFonts(dotenv.get('APP_ID')).metadataNameFontWeight),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                context.loc.loginWithEmail_cancelButton,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                // validate email
                if (!_formKey.currentState!.validate()) {
                  return;
                }

                Navigator.pop(context, _emailController.text);
              },
              child: Text(
                context.loc.loginWithEmail_okButton,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.loc.loginWithEmail_ValidationError;
                  }
                  final regex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                  if (!regex.hasMatch(value)) {
                    return context.loc.loginWithEmail_ValidationError;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: context.loc.loginWithEmail_Hint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    ;
  }
}
