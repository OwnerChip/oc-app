import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final WalletType _metamask = WalletType(
    "Metamask",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/metamask.png",
    'https://metamask.app.link');

final WalletType _trustWallet = WalletType(
    "Trust Wallet",
    "${dotenv.get('IMAGE_ASSETS_BASE_URL')}/trustwallet.png",
    'https://link.trustwallet.com');

final Map<String, WalletType> walletConfig = {
  'Trust Wallet': _trustWallet,
  'Metamask Wallet': _metamask,
};
