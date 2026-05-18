import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum EWalletType {
  ownerCard,
  walletConnect,
  privy,

  certificateCard,
}

final WalletType _ownerCard = WalletType(
  'OwnerCard',
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo_splash.png",
  EWalletType.ownerCard,
);

final WalletType _walletConnect = WalletType(
  "WalletConnect",
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/metamask.png",
  EWalletType.walletConnect,
);

final WalletType _privy = WalletType(
  "privy",
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/metamask.png",
  EWalletType.privy,
);

final WalletType _certificateCard = WalletType(
  "CertificateCard",
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo_splash.png",
  EWalletType.certificateCard,
);

final Map<EWalletType, WalletType> walletConfig = {
  EWalletType.ownerCard: _ownerCard,
  EWalletType.walletConnect: _walletConnect,
  EWalletType.privy: _privy,
  EWalletType.certificateCard: _certificateCard,
};
