import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/services/providers/blockchainData.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifierData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/web3.services.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

class MyBalanceNotifier extends Notifier<MyBalanceNotifierData> {
  MyBalanceNotifier() : super();

  static final Map<int, String> _listItemAssetPath = {
    1: "assets/images/common/eth_icon.png",
    137: "assets/images/common/matic_icon.png",
  };

  @override
  MyBalanceNotifierData build() {
    return MyBalanceNotifierData.initial();
  }

  Future<void> updateBalance() async {
    final userSession = ref.read(userSessionProvider);
    if (userSession == null) {
      return;
    }

    try {
      final newListItems = <MyBalanceListItem>[];

      for (final chain in chainConfig.entries) {
        final client = getWeb3Client(chain.value.rpcUrl);
        final balance =
            (await client.getBalance(userSession.userWalletAddress)).getInWei;
        final priceInFiat = await ref
            .read(ethPriceProvider(chain.value.nativeTokenSymbol).future);
        newListItems.add(MyBalanceListItem(
          balance: balance,
          chain: chain.key,
          symbol: chain.value.nativeTokenSymbol,
          name: chain.value.nativeTokenSymbol,
          iconPath: _listItemAssetPath[chain.key]!,
          balanceEur: balance / BigInt.from(10).pow(18) * priceInFiat['EUR']!,
        ));

        for (final token in chainTokenConfigs[chain.key]!) {
          final deployedContract = await token.getDeployedContract();
          final balance = await client.call(
            contract: deployedContract,
            function: deployedContract.function('balanceOf'),
            params: [userSession.userWalletAddress],
          );

          final balanceInEther = balance.first as BigInt;

          final priceInFiat =
              await ref.read(ethPriceProvider(token.symbol).future);

          newListItems.add(MyBalanceListItem(
            balance: balanceInEther,
            chain: chain.key,
            name: token.symbol,
            symbol: token.symbol,
            iconPath: token.iconPath,
            decimals: token.decimals,
            balanceEur:
                balanceInEther / BigInt.from(10).pow(token.decimals) * priceInFiat['EUR']!,
            token: chainTokenConfigs[chain.key]!.indexOf(token),
          ));
        }
      }

      state = state.copyWith(
        myBalanceList: newListItems,
        initialized: true,
      );
    } catch (e, st) {
      Sentry.captureException(e);
      talker.error(
        "Error updating balance: $e",
        st,
      );

      state = state.copyWith(error: true);
    }
  }

  Future<void> sendTransaction(
      MyBalanceListItem item, String address, BigInt amount) async {}

  void setMyBalanceListItem(MyBalanceListItem? myBalanceListItem) {
    state = state.copyWith(myBalanceListItem: myBalanceListItem);
  }
}

final myBalanceNotifierProvider =
    NotifierProvider<MyBalanceNotifier, MyBalanceNotifierData>(
  MyBalanceNotifier.new,
);
