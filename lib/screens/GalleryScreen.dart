//import packages
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/domain/oc/oc_owned_nft.dart';
import 'package:ownerchip_whitelabel/services/providers/common/notifierPaginationData.dart';
import 'package:ownerchip_whitelabel/services/providers/nft/nftForOwner/nftForOwnerData.dart';
import 'package:ownerchip_whitelabel/services/providers/nft/nftMintedByUser/nftMintedByUserData.dart';
import 'package:ownerchip_whitelabel/services/providers/nft/paginationNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/utils/urls.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/GalleryItem.dart';
import 'package:url_launcher/url_launcher.dart';

final _pageBucket = PageStorageBucket();

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

  late final ScrollController _ownedNftsScrollController;
  late final ScrollController _mintedNftsScrollController;

  late final RefreshController _ownedNftsRefreshController;
  late final RefreshController _mintedNftsRefreshController;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
    );
    _ownedNftsScrollController = ScrollController();
    _ownedNftsRefreshController = RefreshController(
      initialRefresh: false,
      initialLoadStatus: LoadStatus.idle,
    );
    _mintedNftsScrollController = ScrollController();
    _mintedNftsRefreshController = RefreshController(
      initialRefresh: false,
      initialLoadStatus: LoadStatus.idle,
    );
  }

  @override
  void dispose() {
    _mintedNftsScrollController.dispose();
    _mintedNftsRefreshController.dispose();

    _ownedNftsScrollController.dispose();
    _ownedNftsRefreshController.dispose();

    _pageController.dispose();

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
    final OCNFTsMintedByUserData ocNFTsMintedByUserNotifier =
        ref.watch(ocNFTsMintedByUserNotifierProvider);

    final UserSession? userSession = ref.watch(userSessionProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        showBackButton: true,
        text: context.loc.myCollection,
      ),
      body: PageStorage(
        bucket: _pageBucket,
        child: Padding(
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
              // Owned by me
              _buildGalleryPage(
                ocNFTsForOwnerData: ocNFTsForOwnerData,
                refreshController: _ownedNftsRefreshController,
                userSession: userSession,
                getNotifier: () => ref.read(ocNFTsForOwnerProvider.notifier),
                buildEmptyState: (context) => _buildYouDontOwnItems(context),
                buildErrorState: (context) =>
                    _buildErrorLoadingOwnedItems(context),
                scrollController: _ownedNftsScrollController,
                pageStorageKey: 'owned',
              ),
              // Created by me
              _buildGalleryPage(
                ocNFTsForOwnerData: ocNFTsMintedByUserNotifier,
                refreshController: _mintedNftsRefreshController,
                userSession: userSession,
                getNotifier: () =>
                    ref.read(ocNFTsMintedByUserNotifierProvider.notifier),
                buildEmptyState: (context) =>
                    _buildYouHaventMintedAnyItems(context, userSession!.jwt),
                buildErrorState: (context) =>
                    _buildErrorLoadingCreatedItems(context),
                scrollController: _mintedNftsScrollController,
                pageStorageKey: 'minted',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: Theme.of(context).textTheme.bodyLarge,
        unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildGalleryPage({
    required NotifierPaginationData<OcOwnedNft, Map<int, String?>>
        ocNFTsForOwnerData,
    required RefreshController refreshController,
    UserSession? userSession,
    required IPaginationNotifier Function() getNotifier,
    required Widget Function(BuildContext context) buildEmptyState,
    required Widget Function(BuildContext context) buildErrorState,
    required ScrollController scrollController,
    required String pageStorageKey,
  }) {
    return Builder(builder: (context) {
      if (!ocNFTsForOwnerData.loading &&
          ocNFTsForOwnerData.data.isEmpty &&
          ocNFTsForOwnerData.canLoadMore &&
          !ocNFTsForOwnerData.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getNotifier().refreshPage();
        });
      }
      if (ocNFTsForOwnerData.loading &&
          ocNFTsForOwnerData.data.isEmpty &&
          !ocNFTsForOwnerData.error) {
        return _buildProgressLoader();
      }
      if ((userSession == null ||
          userSession.userWalletAddress == zeroAddress)) {
        return _buildWalletConnectWidget(context);
      }

      return SmartRefresher(
        controller: refreshController,
        physics: const BouncingScrollPhysics(),
        enablePullUp: true,
        onRefresh: () async {
          refreshController.requestRefresh();
          refreshController.loadComplete();
          getNotifier().refreshPage().then((_) {
            refreshController.refreshCompleted();
          });
          talker.debug('refreshed');
        },
        onLoading: () {
          if (ocNFTsForOwnerData.data.isEmpty) {
            return;
          }

          refreshController.requestLoading();
          getNotifier().loadNextPage().then((_) {
            refreshController.loadComplete();
          });
          talker.debug('loading');
        },
        header: CustomHeader(
          builder: (context, mode) {
            return _buildHeader(
              context,
              mode: mode,
              error: ocNFTsForOwnerData.error,
            );
          },
        ),
        footer: CustomFooter(
          builder: (context, mode) {
            return _buildFooter(
              context,
              mode: mode,
              canLoadMore: ocNFTsForOwnerData.canLoadMore,
              empty: ocNFTsForOwnerData.data.isEmpty,
              error: ocNFTsForOwnerData.error,
            );
          },
        ),
        child: ocNFTsForOwnerData.data.isEmpty
            ? ocNFTsForOwnerData.error
                ? buildErrorState(context)
                : buildEmptyState(context)
            : _buildGrid(
                data: ocNFTsForOwnerData.data,
                controller: scrollController,
                pageStorageKey: pageStorageKey,
              ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context, {
    RefreshStatus? mode,
    bool error = false,
  }) {
    return SizedBox(
      height: 55.0,
      child: Center(
        child: Column(
          children: [
            Text(
              mode == RefreshStatus.refreshing
                  ? context.loc.galleryRefreshing
                  : context.loc.galleryPullToRefresh,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  SizedBox _buildFooter(
    BuildContext context, {
    LoadStatus? mode,
    bool canLoadMore = false,
    bool empty = false,
    bool error = false,
  }) {
    if (empty) {
      return const SizedBox();
    }
    return SizedBox(
      height: 90.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (mode == LoadStatus.loading) ...[
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: CustomColors(dotenv.get('APP_ID')).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                !canLoadMore
                    ? context.loc.galleryNoMoreItems
                    : error
                        ? context.loc.galleryErrorLoadingMore
                        : mode == LoadStatus.loading
                            ? context.loc.galleryLoadingMore
                            : context.loc.galleryLoadMore,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
        ],
      ),
    );
  }

  Column _buildYouDontOwnItems(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            context.loc.youDoNotOwnAnyItems,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]);
  }

  Column _buildYouHaventMintedAnyItems(
    BuildContext context,
    JwtToken jwtToken,
  ) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          Text(
            context.loc.youHaveNotMintedAnyItems,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            height: 20,
          ),
          if (jwtToken.canMint())
            CustomRoundedButton(
                text: context.loc.orderChips,
                onPressed: () => {
                      launchUrl(Uri.parse(context.loc.orderChipsUrl),
                          mode: LaunchMode.externalApplication)
                    },
                width: 250)
          else
            CustomRoundedButton(
                text: context.loc.signupAsCertifier,
                onPressed: () => {
                      launchUrl(Uri.parse(getBecomeACreatorUrl(jwtToken.raw)),
                          mode: LaunchMode.externalApplication)
                    },
                width: 250),
        ]);
  }

  GridView _buildGrid({
    required List<OcOwnedNft> data,
    required ScrollController controller,
    required String pageStorageKey,
  }) {
    return GridView.builder(
      key: PageStorageKey(pageStorageKey),
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
      controller: controller,
      itemBuilder: (context, index) {
        return GalleryItem(
          item: data[index],
          ref: ref,
        );
      },
    );
  }

  Widget _buildErrorLoadingOwnedItems(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          context.loc.errorLoadingOwnedItems,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildErrorLoadingCreatedItems(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Text(
          context.loc.errorLoadingCreatedItems,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Column _buildWalletConnectWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
          onPressed: (() => {walletPopupBuilder(context, ref)}),
        )
      ],
    );
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
