import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';

import 'CustomCard.dart';

//stateless widget boilerplate
class AttachmentBox extends StatelessWidget {
  const AttachmentBox({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    required this.isPrivate,
  });

  final String text;
  final IconData icon;
  final Function onTap;
  final bool isPrivate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: CustomCard(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding:
            const EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                //min space
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    text.length > 20 ? '${text.substring(0, 20)}...' : text,
                    style: TextStyle(
                      color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              isPrivate
                  ? Icon(
                      size: 17,
                      Icons.shield_outlined,
                      color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                    )
                  : Container(),
            ],
          )
        ],
      ),
    );
  }
}
