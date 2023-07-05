import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MoreInfoButtons {
  List<MoreInfoButton> roundedButtons = [];
  List<MoreInfoButton> outlinedRoundedButtons = [];

  MoreInfoButtons(appEnvironment, loc) {
    switch (appEnvironment) {
      case 'ownerchip':
        roundedButtons = [
          MoreInfoButton(
              loc.watchTutorial, "http://www.ownerchip.com/tutorial"),
          MoreInfoButton(loc.viewProjects, "http://www.ownerchip.com/projects"),
          MoreInfoButton(loc.orderChips, "http://www.ownerchip.com/orderchips"),
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(
              loc.support, 'https://www.ownerchip.com/en/support.html'),
          MoreInfoButton(loc.legal,
              'https://www.ownerchip.com/en/app-support-legal-information.html')
        ];
        break;
      case 'stebo':
        roundedButtons = [
          MoreInfoButton(
              loc.watchTutorial, "http://www.ownerchip.com/tutorial"),
          MoreInfoButton(
              loc.viewGallery, "https://www.steboart.com/en/galerie"),
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(
              loc.support, 'https://www.ownerchip.com/en/support.html'),
          MoreInfoButton(loc.legal,
              'https://www.ownerchip.com/en/app-support-legal-information.html')
        ];
        break;
      default:
        roundedButtons = [
          MoreInfoButton(
              loc.watchTutorial, "http://www.ownerchip.com/tutorial"),
          MoreInfoButton(loc.viewProjects, "http://www.ownerchip.com/projects"),
          MoreInfoButton(loc.orderChips, "http://www.ownerchip.com/orderchips"),
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(
              loc.support, 'https://www.ownerchip.com/en/support.html'),
          MoreInfoButton(loc.legal,
              'https://www.ownerchip.com/en/app-support-legal-information.html')
        ];
    }
  }
}
