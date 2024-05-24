import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/domain/walletType/eWalletType.dart';
import 'package:ownerchip_whitelabel/domain/walletType/walletType.dart';



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

final WalletType _web3auth = WalletType(
  "web3auth",
  "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/metamask.png",
  EWalletType.web3auth,
);

final Map<EWalletType, WalletType> walletConfig = {
  EWalletType.ownerCard: _ownerCard,
  EWalletType.walletConnect: _walletConnect,
  EWalletType.web3auth: _web3auth,
};
