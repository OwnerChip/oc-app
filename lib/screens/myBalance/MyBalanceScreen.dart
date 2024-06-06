import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/chains.dart';
import 'package:ownerchip_whitelabel/domain/myBalance/myBalanceListItem.dart';
import 'package:ownerchip_whitelabel/screens/myBalance/myBalanceWithdrawPage.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifierData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class MyBalancePage extends ConsumerStatefulWidget {
  const MyBalancePage({super.key});

  static const String routeName = '/myBalance';

  @override
  ConsumerState<MyBalancePage> createState() => _MyBalancePageState();
}

class _MyBalancePageState extends ConsumerState<MyBalancePage> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController = RefreshController();

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    ref.read(myBalanceNotifierProvider.notifier).updateBalance();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(myBalanceNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        text: context.loc.myBalanceTitle,
        overrideBackButton: () {
          if (_currentPage == 1) {
            FocusScope.of(context).unfocus();

            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.ease,
            );
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      body: SafeArea(
        child: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (index) {
            _currentPage = index;
            if (mounted) {
              setState(() {});
            }
          },
          children: [
            _buildList(
              context,
              data: data,
              key: const PageStorageKey('myBalanceList'),
            ),
            MyBalanceWithdrawPage(
              isVisible: _currentPage == 1,
              onBack: () {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                FocusScope.of(context).unfocus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context, {
    required MyBalanceNotifierData data,
    required Key key,
  }) {
    return data.error
        ? _buildErrorWidget(context)
        : data.initialized
            ? _buildCryptoList(
                context,
                data,
                key,
              )
            : _buildListLoadingState();
  }

  CustomHeader _buildListRefreshHeader() {
    return CustomHeader(
      builder: (context, mode) {
        return Container(
          alignment: Alignment.center,
          child: mode == RefreshStatus.idle
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: CustomColors(
                        dotenv.get('APP_ID'),
                      ).primaryColor,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(context.loc.myBalancePullToRefresh),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: CustomColors(
                        dotenv.get('APP_ID'),
                      ).primaryColor,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Text(
                      context.loc.myBalanceRefreshing,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: CustomColors(
                              dotenv.get('APP_ID'),
                            ).primaryColor,
                          ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Center _buildListLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: CustomColors(
          dotenv.get('APP_ID'),
        ).primaryColor,
      ),
    );
  }

  Widget _buildCryptoList(
      BuildContext context, MyBalanceNotifierData data, Key key) {
    final data = ref.watch(myBalanceNotifierProvider);

    return SmartRefresher(
      key: key,
      controller: _refreshController,
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.vertical,
      enablePullDown: true,
      enablePullUp: false,
      header: _buildListRefreshHeader(),
      onRefresh: () {
        ref.read(myBalanceNotifierProvider.notifier).updateBalance().then((_) {
          _refreshController.refreshCompleted();
        }).catchError((e) {
          _refreshController.refreshCompleted();
        });
      },
      child: ListView(
        key: ValueKey(data.myBalanceList),
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        children: [
          _buildHeader(
            context,
            data: data,
          ),
          ...data.myBalanceList.map(
            (item) => _buildCryptoCurrencyListItem(
              item,
            ),
          ),
        ],
      ),
    );
  }

  Center _buildErrorWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.loc.myBalanceError,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(
            height: 16,
          ),
          CustomOutlinedButton(
            onPressed: () {
              ref.read(myBalanceNotifierProvider.notifier).updateBalance();
            },
            buttonText: context.loc.myBalanceRetry,
          ),
        ],
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
          _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
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
                    Text(chainConfig[item.chain]!.networkName),
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        item.balanceInEtherString,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${item.balanceEur.toStringAsFixed(2)} €",
                        style:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column _buildHeader(
    BuildContext context, {
    required MyBalanceNotifierData data,
  }) {
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
                "${data.myBalanceList.map((e) => e.balanceEur).reduce((a, b) => a + b).toStringAsFixed(2)} €",
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
