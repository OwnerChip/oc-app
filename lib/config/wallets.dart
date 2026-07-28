import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Persisted by NAME (see [WalletType.toJson]); legacy installs may still hold
/// an integer index, so DO NOT reorder these members.
enum EWalletType {
  ownerCard,
  walletConnect,
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


final Map<EWalletType, WalletType> walletConfig = {
  EWalletType.ownerCard: _ownerCard,
  EWalletType.walletConnect: _walletConnect,
};