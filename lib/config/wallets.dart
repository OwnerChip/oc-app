import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final WalletType _smartCard = WalletType('OwnerCard',
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/app_logo_splash.png", '');

final WalletType _metamask = WalletType(
    "Metamask",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/metamask.png",
    'https://metamask.app.link');

final WalletType _trustWallet = WalletType(
    "Trust Wallet",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/trustwallet.png",
    'https://link.trustwallet.com');

final WalletType _zerionWallet = WalletType(
    "Zerion Wallet",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/zerionwallet.png",
    'https://wallet.zerion.io');

final WalletType _rainbowWallet = WalletType(
    "Rainbow Wallet",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/rainbowwallet.webp",
    'https://rnbwapp.com');

final WalletType _zengoWallet = WalletType(
    "ZenGo Wallet",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/zengowallet.webp",
    'zengo://get.zengo.com');

final Map<String, WalletType> walletConfig = {
  'ocSmartCard': _smartCard,
  'https://trustwallet.com': _trustWallet,
  'https://metamask.io/': _metamask,
  'https://zerion.io': _zerionWallet,
  'https://rainbow.me': _rainbowWallet,
  'https://zengo.com': _zengoWallet,
};
