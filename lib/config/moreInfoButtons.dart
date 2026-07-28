import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

class MoreInfoButtons {
  List<MoreInfoButton> roundedButtons = [];
  List<MoreInfoButton> outlinedRoundedButtons = [];

  MoreInfoButtons(appEnvironment, dynamic loc) {
    switch (appEnvironment) {
      case 'ownerchip':
        roundedButtons = [
          MoreInfoButton(loc.viewProjects, loc.projectsUrl),
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
