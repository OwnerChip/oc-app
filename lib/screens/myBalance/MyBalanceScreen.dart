import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/myBalanceWithdrawPage.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';

class MyBalancePage extends ConsumerStatefulWidget {
  const MyBalancePage({super.key});

  static const String routeName = '/myBalance';

  @override
  ConsumerState<MyBalancePage> createState() => _MyBalancePageState();
}

class _MyBalancePageState extends ConsumerState<MyBalancePage> {
  final ScrollController _scrollController = ScrollController();

  List<MyBalanceListItem> _myBalanceList = [];

  @override
  void initState() {
    super.initState();
    _myBalanceList.add(
      const MyBalanceListItem(
        network: "Ethereum Mainnet",
        name: "ETH",
        balance: "0,674",
        balanceEur: "1.373",
        iconPath: "assets/images/common/eth_icon.png",
      ),
    );
    _myBalanceList.add(const MyBalanceListItem(
      network: "Polygon Mainnet",
      name: "MATIC",
      balance: "100,54",
      balanceEur: "79,46",
      iconPath: "assets/images/common/matic_icon.png",
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(myBalanceNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        text: context.loc.myBalanceTitle,
        overrideBackButton: () {
          if (data.myBalanceListItem != null) {
            ref.read(myBalanceNotifierProvider.notifier).setMyBalanceListItem(
                  null,
                );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: data.myBalanceListItem != null
              ? const MyBalanceWithdrawPage()
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(context),
                    ),
                    SliverList.builder(
                        itemCount: _myBalanceList.length,
                        itemBuilder: (context, index) {
                          return _buildCryptoCurrencyListItem(
                            _myBalanceList[index],
                          );
                        }),
                  ],
                ),
        ),
      ),
    );
  }

  Padding _buildCryptoCurrencyListItem(
    MyBalanceListItem item,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 16.0,
      ),
      child: InkWell(
        onTap: () {
          ref.read(myBalanceNotifierProvider.notifier).setMyBalanceListItem(
                item,
              );
        },
        child: Container(
          decoration: BoxDecoration(
            color: CustomColors(dotenv.get('APP_ID')).cardColor,
            borderRadius: BorderRadius.circular(
              16,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            child: Row(
              children: [
                Image.asset(
                  item.iconPath,
                  width: 56,
                  height: 56,
                ),
                const SizedBox(
                  width: 16,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.network),
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      item.balance,
                      style:
                          Theme.of(context).textTheme.headlineMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      "${item.balanceEur} €",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(
          height: 32,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                context.loc.myBalanceTotalBalance,
                style: Theme.of(context).textTheme.bodySmall!,
              ),
              Text(
                "~1.443,47 €",
                style: Theme.of(context).textTheme.displayLarge!.copyWith(),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Text(
            context.loc.myBalanceChoseCrypto,
            style: Theme.of(context).textTheme.bodySmall!,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
      ],
    );
  }
}
