//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import screens

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

class MoreInfoScreen extends ConsumerStatefulWidget {
  const MoreInfoScreen({Key? key}) : super(key: key);

  static const routeName = '/moreInfo';

  @override
  _MoreInfoScreenState createState() => _MoreInfoScreenState();
}

class _MoreInfoScreenState extends ConsumerState<MoreInfoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
          mainAxisAlignment: MainAxisAlignment.center,
          flexSides: 0,
          padding: const EdgeInsets.only(top: 0, bottom: 15),
          children: [
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  textAlign: TextAlign.center,
                  context.loc.infoScreenText,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            CustomRoundedButton(
                text: context.loc.watchTutorial,
                onPressed: () => {
                      launchUrl(Uri.parse(dotenv.get('TUTORIAL_PAGE_URL')),
                          mode: LaunchMode.externalApplication)
                    },
                width: 250),
            const SizedBox(height: 10),
            CustomRoundedButton(
                text: context.loc.viewProjects,
                onPressed: () => {
                      launchUrl(Uri.parse(dotenv.get('PROJECTS_PAGE_URL')),
                          mode: LaunchMode.externalApplication)
                    },
                width: 250),
            const SizedBox(height: 10),
            dotenv.get('APP_ID') == 'ownerchip'
                ? CustomRoundedButton(
                    text: context.loc.orderChips,
                    onPressed: () => {
                          launchUrl(Uri.parse(dotenv.get('ORDER_CHIPS_URL')),
                              mode: LaunchMode.externalApplication)
                        },
                    width: 250)
                : Container(),
            const SizedBox(height: 60),
            CustomOutlinedButton(
                buttonText: context.loc.support,
                onPressed: () => {
                      launchUrl(Uri.parse(dotenv.get('SUPPORT_PAGE_URL')),
                          mode: LaunchMode.externalApplication)
                    }),
            const SizedBox(height: 10),
            CustomOutlinedButton(
                buttonText: context.loc.legal,
                onPressed: () => {
                      launchUrl(Uri.parse(dotenv.get('LEGAL_PAGE_URL')),
                          mode: LaunchMode.externalApplication)
                    }),
            const SizedBox(height: 20),
            Text('Version: ${dotenv.get('VERSION_NUMBER')}',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
    );
  }
}
