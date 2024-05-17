//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/services/providers/nft/nftForOwner/nftForOwnerData.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/GalleryItem.dart';
import 'package:url_launcher/url_launcher.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({
    super.key,
  });

  static const routeName = '/gallery';

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  late final PageController _pageController;
  late final RefreshController _ownedNftsRefreshController;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
    );
    _ownedNftsRefreshController = RefreshController(
      initialRefresh: false,
      initialLoadStatus: LoadStatus.idle,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ownedNftsRefreshController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    final OCNFTsForOwnerData ocNFTsForOwnerData =
        ref.watch(ocNFTsForOwnerProvider);
    // final AsyncValue<List?> ownedOcNfts = ref.watch(getOcNftsForOwner);
    // final AsyncValue<List?> mintedOcNfts = ref.watch(getOcNftsMintedByUser);
    final UserSession? userSession = ref.watch(userSessionProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        showBackButton: true,
        text: context.loc.myCollection,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: CustomAppBar.kCustomAppBarHeight,
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: (int page) {
            _currentPage = page;
            setState(() {});
          },
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // Owned NFTs

            if (ocNFTsForOwnerData.loading &&
                ocNFTsForOwnerData.data.isEmpty &&
                !ocNFTsForOwnerData.error)
              _buildProgressLoader()
            else if (ocNFTsForOwnerData.data.isEmpty &&
                ocNFTsForOwnerData.error)
              if (userSession == null ||
                  userSession.userWalletAddress == zeroAddress)
                _buildWalletConnectWidget(context)
              else
                Container()
            else
              SmartRefresher(
                controller: _ownedNftsRefreshController,
                physics: const BouncingScrollPhysics(),
                enablePullUp: true,
                onRefresh: () async {
                  _ownedNftsRefreshController.requestRefresh();
                  ref
                      .read(ocNFTsForOwnerProvider.notifier)
                      .refreshPage()
                      .then((_) {
                    _ownedNftsRefreshController.refreshCompleted();
                  });
                  talker.debug('refreshed');
                },
                onLoading: () {
                  _ownedNftsRefreshController.requestLoading();
                  ref
                      .read(ocNFTsForOwnerProvider.notifier)
                      .loadNextPage()
                      .then((_) {
                    _ownedNftsRefreshController.loadComplete();
                  });
                  talker.debug('loading');
                },
                header: CustomHeader(
                  builder: (context, mode) {
                    return Container(
                      height: 55.0,
                      child: Center(
                        child: Text(
                          mode == RefreshStatus.refreshing
                              ? context.loc.galleryRefreshing
                              : context.loc.galleryPullToRefresh,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
                footer: CustomFooter(
                  builder: (context, mode) {
                    return Container(
                      height: 55.0,
                      child: Center(
                        child: Text(
                          mode == LoadStatus.loading
                              ? context.loc.galleryLoadingMore
                              : context.loc.galleryLoadMore,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    );
                  },
                ),
                child: ocNFTsForOwnerData.data.isEmpty
                    ? _buildYouDontOwnItems(context)
                    : _buildGrid(ocNFTsForOwnerData.data),
              ),

            // Minted NFTs
            // mintedOcNfts.when(
            //     data: (data) {
            //       if (data?.isEmpty ?? true) {
            //         return _buildYouHaventMintedAnyItems(context);
            //       } else {
            //         return _buildGrid(data);
            //       }
            //     },
            //     error: (e, s) {
            //       if (userSession == null ||
            //           userSession.userWalletAddress == zeroAddress) {
            //         return _buildWalletConnectWidget(context);
            //       } else {
            //         return Container();
            //       }
            //     },
            //     loading: () => _buildProgressLoader()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Container(),
            label: context.loc.ownedByMe,
          ),
          BottomNavigationBarItem(
            icon: Container(),
            label: context.loc.createdByMe,
          ),
        ],
        currentIndex: _currentPage,
        selectedItemColor: CustomColors(dotenv.get('APP_ID')).accentColor,
        backgroundColor: CustomColors(dotenv.get('APP_ID')).cardColor,
        elevation: 10,
        onTap: _onItemTapped,
      ),
    );
  }

  Column _buildYouDontOwnItems(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      Text(
        context.loc.youDoNotOwnAnyItems,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }

  Column _buildYouHaventMintedAnyItems(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      Text(
        context.loc.youHaveNotMintedAnyItems,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 20),
      CustomRoundedButton(
          text: context.loc.orderChips,
          onPressed: () => {
                launchUrl(Uri.parse(context.loc.orderChipsUrl),
                    mode: LaunchMode.externalApplication)
              },
          width: 250)
    ]);
  }

  GridView _buildGrid(List<OcOwnedNft> data) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 0.95,
        crossAxisCount: 2,
        // Number of columns
        crossAxisSpacing: 12.0,
        // Horizontal space between items
        mainAxisSpacing: 12.0,
        // Vertical space between items
        mainAxisExtent: 196,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: data!.length,
      itemBuilder: (context, index) {
        return GalleryItem(
          item: data[index],
          ref: ref,
        );
      },
    );
  }

  Column _buildWalletConnectWidget(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      Text(
        context.loc.pleaseConnectWalletToViewItems,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      CustomRoundedButton(
          width: 250,
          text: context.loc.connectWallet,
          onPressed: (() => {walletPopupBuilder(context, ref)}))
    ]);
  }

  Widget _buildProgressLoader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: CustomColors(dotenv.get('APP_ID')).primaryColor,
          ),
        ),
      ],
    );
  }
}
