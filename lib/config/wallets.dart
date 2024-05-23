import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/walletType/walletType.dart';

final WalletType _ownerCard = WalletType(
  'OwnerCard',
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo_splash.png",
);

final WalletType _walletConnect = WalletType(
  "WalletConnect",
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/metamask.png",
);

final Map<String, WalletType> walletConfig = {
  'ownerCard': _ownerCard,
  'walletConnect': _walletConnect,
};
