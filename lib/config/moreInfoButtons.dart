import 'package:ownerchip_whitelabel/domain/moreInfoButton/moreInfoButton.dart';

class MoreInfoButtons {
  List<MoreInfoButton> roundedButtons = [];
  List<MoreInfoButton> outlinedRoundedButtons = [];

  MoreInfoButtons(appEnvironment, loc) {
    switch (appEnvironment) {
      case 'ownerchip':
        roundedButtons = [
          MoreInfoButton(loc.viewProjects, loc.projectsUrl),
          MoreInfoButton(loc.orderChips, loc.orderChipsUrl),
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(loc.support, loc.supportUrl),
          MoreInfoButton(loc.legal, loc.legalUrl)
        ];
        break;
      case 'stebo':
        roundedButtons = [
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(loc.support, loc.supportUrl),
          MoreInfoButton(loc.legal, loc.legalUrl)
        ];
        break;
      case 'stilami':
        roundedButtons = [
          MoreInfoButton(loc.stilamiIdentityButtonText, loc.stilamiIdentityUrl),
          MoreInfoButton(loc.collectionsButtonText, loc.collectionsUrl),
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(loc.support, loc.supportUrl),
          MoreInfoButton(loc.legal, loc.legalUrl)
        ];
        break;
      default:
        roundedButtons = [
          MoreInfoButton(loc.viewProjects, loc.projectsUrl),
          MoreInfoButton(loc.orderChips, loc.orderChipsUrl),
        ];
        outlinedRoundedButtons = [
          MoreInfoButton(loc.support, loc.supportUrl),
          MoreInfoButton(loc.legal, loc.legalUrl)
        ];
    }
  }
}
