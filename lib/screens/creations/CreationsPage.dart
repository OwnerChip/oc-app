import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/screens/TransferScreen.dart';
import 'package:ownerchip_whitelabel/screens/creations/creationCancel_popup.dart';
import 'package:ownerchip_whitelabel/screens/creations/restoreToken_popup.dart';
import 'package:ownerchip_whitelabel/screens/nftActionsScreenMixin.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/backendCreationService.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomPopup.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/SpinningLoadingSvg.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:reown_appkit/solana/solana_web3/solana_web3.dart';

class CreationsPage extends ConsumerStatefulWidget {
  const CreationsPage({super.key});

  static String routeName = '/creations';

  @override
  ConsumerState<CreationsPage> createState() => _CreationsPageState();
}

class _CreationsPageState extends ConsumerState<CreationsPage>
    with NftActionScreenMixin<CreationsPage> {
  final RefreshController _refreshController = RefreshController();

  String? _selectedCreationId;

  @override
  void initState() {
    super.initState();
    pageKey = 'CreationsPage';
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creations = ref.watch(creationsNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (creations.initialized &&
          creations.data != null &&
          creations.data!.isEmpty) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return CustomOverlay(
      show: isLoading,
      content: SpinningLoadingSvg(
        onPressed: () {
          setState(() {
            isLoading = false;
          });
        },
        loadingText: loadingText,
        rotateIcon: true,
        svgPath: loadingSvgPath,
      ),
      child: Scaffold(
          appBar: CustomAppBar(
            text: context.loc.nftCreationsPageTitle,
          ),
          body: SmartRefresher(
            enablePullDown: true,
            enablePullUp: creations.page < creations.totalPages,
            controller: _refreshController,
            onRefresh: () async {
              _refreshController.requestRefresh();
              await ref.read(creationsNotifierProvider.notifier).load();
              _refreshController.refreshCompleted();
            },
            onLoading: () async {
              _refreshController.requestLoading();

              if (creations.page < creations.totalPages) {
                await ref
                    .read(creationsNotifierProvider.notifier)
                    .load(page: creations.page + 1);
              }

              _refreshController.loadComplete();
            },
            header: CustomHeader(
              builder: (context, mode) => _buildHeader(context, mode: mode),
            ),
            footer: CustomFooter(
              height: 55,
              builder: (context, mode) => _buildFooter(context, mode),
            ),
            child: ListView.builder(
              itemCount: creations.data?.length ?? 0,
              itemBuilder: (context, index) {
                final metadata = creations.data![index];
                if (metadata.type ==
                    DigitalTwinCreationMetadataTypeEnum.single) {
                  return _buildSingleTwin(metadata, context, creations);
                } else if (metadata.type ==
                    DigitalTwinCreationMetadataTypeEnum.multiple) {
                  return _buildMultiTwin(metadata, context, creations);
                }

                return const SizedBox();
              },
            ),
          )),
    );
  }

  Widget _buildMultiTwin(DigitalTwinMetadata metadata, BuildContext context,
      CreationsData creations) {
    final numberOfTokens = metadata.seriesItems?.length ?? 0;
    final quantity = metadata.quantity ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(
              16.0,
            ),
            onTap: () {
              setState(() {
                if (_selectedCreationId == metadata.id) {
                  _selectedCreationId = null;
                } else {
                  _selectedCreationId = metadata.id;
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    16.0,
                  ),
                  color: _selectedCreationId == metadata.id
                      ? Colors.grey[300]
                      : Colors.transparent),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                  ),
                  if (metadata.imageLink != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Image.network(
                          metadata.imageLink!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const SizedBox(
                    width: 32,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          metadata.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          metadata.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(context.loc.nftCreationMultiSeriesDescription(
                          quantity.toString(),
                        ))
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (metadata.id == _selectedCreationId) ...[
          const SizedBox(
            height: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.loc.nftCreationMultiSeriesTitle),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(context.loc.nftCreationMultiSeriesStatus(
                        numberOfTokens.toString(), quantity.toString())),
                    const SizedBox(
                      height: 8,
                    ),
                    Builder(
                      builder: (context) {
                        final width = MediaQuery.of(context).size.width - 64;

                        final progress =
                            quantity > 0 ? numberOfTokens / quantity : 0.0;
                        // final progress = 0.5;

                        return Stack(
                          children: [
                            Container(
                              width: double.maxFinite,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Container(
                              width: width * progress,
                              height: 20,
                              decoration: BoxDecoration(
                                color: CustomColors(dotenv.get("APP_ID"))
                                    .primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                        width: double.maxFinite,
                        child: CustomRoundedButton(
                            text: context
                                .loc.nftCreationMultiSeriesActivateButton,
                            onPressed: () {})),
                    const SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      width: double.maxFinite,
                      child: CustomOutlinedButton(
                          onPressed: () {},
                          buttonText: context.loc.nftCreationMultiSeriesPause),
                    ),
                  ],
                ),
              ),
            ),
          )
        ]
      ],
    );
  }

  InkWell _buildSingleTwin(DigitalTwinMetadata metadata, BuildContext context,
      CreationsData creations) {
    return InkWell(
      onTap: () {
        _onTapSingle(metadata, context, creations);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            if (metadata.imageLink != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  8.0,
                ),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.network(
                    metadata.imageLink!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            const SizedBox(
              width: 32,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    metadata.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    metadata.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Container(
                    child: Text(
                      _getTextByStatus(context, metadata.status),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                ],
              ),
            ),
            Column(
              children: [
                InkWell(
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(
                      Icons.close,
                      size: 24,
                    ),
                  ),
                  onTap: () {
                    String title = "";
                    String description = "";
                    String yes = "";
                    String cancel = "";
                    VoidCallback onYes = () {};

                    if (metadata.status ==
                        DigitalTwinCreationMetadataStatus.toBeBurned) {
                      onYes = () {
                        BackendCreationService.instance
                            .cancelBurnDigitalTwin(metadata.id);
                      };

                      title =
                          context.loc.nft_burn_cancel_confirmation_dialog_title;
                      description = context.loc
                          .nft_burn_cancel_confirmation_dialog_description(
                              metadata.title);
                      yes = context.loc
                          .nft_burn_cancel_confirmation_dialog_cancel_cancel_button;
                      cancel = context.loc
                          .nft_burn_cancel_confirmation_dialog_cancel_keep_button;
                    } else if (metadata.status ==
                        DigitalTwinCreationMetadataStatus.pending) {
                      onYes = () {
                        BackendCreationService.instance
                            .cancelDigitalTwin(metadata.id);
                      };
                      title = context.loc.nft_cancel_confirmation_dialog_title;
                      description = context.loc
                          .nft_cancel_confirmation_dialog_description(
                              metadata.title);
                      yes = context.loc
                          .nft_cancel_confirmation_dialog_cancel_cancel_button;
                      cancel = context.loc
                          .nft_cancel_confirmation_dialog_cancel_keep_button;
                    } else if (metadata.status ==
                        DigitalTwinCreationMetadataStatus.toBeTransferred) {
                      onYes = () {
                        BackendCreationService.instance
                            .cancelTransferDigitalTwin(metadata.id);
                      };

                      title = context
                          .loc.nft_transfer_cancel_confirmation_dialog_title;
                      description = context.loc
                          .nft_transfer_cancel_confirmation_dialog_description(
                              metadata.title);
                      yes = context.loc
                          .nft_transfer_cancel_confirmation_dialog_cancel_cancel_button;
                      cancel = context.loc
                          .nft_transfer_cancel_confirmation_dialog_cancel_cancel_button;
                    }

                    showCustomPopup(
                      context,
                      title,
                      CreationCancelPopup(
                        description: description,
                        yes: yes,
                        cancel: cancel,
                      ),
                    ).then((res) {
                      if (res == true) {
                        onYes();
                      }
                    });
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _onTapSingle(DigitalTwinMetadata metadata, BuildContext context,
      CreationsData creations) {
    if (metadata.status == DigitalTwinCreationMetadataStatus.toBeBurned) {
      _burnItem(
        context,
        creations,
        metadata,
      );
    } else if (metadata.status == DigitalTwinCreationMetadataStatus.pending) {
      _mintItem(
        context,
        creations,
        metadata,
      );
    } else if (metadata.status ==
        DigitalTwinCreationMetadataStatus.toBeTransferred) {
      _transferItem(
        context,
        creations,
        metadata,
      );
    }
  }

  String _getTextByStatus(
      BuildContext context, DigitalTwinCreationMetadataStatus status) {
    switch (status) {
      case DigitalTwinCreationMetadataStatus.draft:
      case DigitalTwinCreationMetadataStatus.minted:
      case DigitalTwinCreationMetadataStatus.burned:
      case DigitalTwinCreationMetadataStatus.unknown:
        return "";
      case DigitalTwinCreationMetadataStatus.pending:
        return context.loc.nftCreationsPagePending;
      case DigitalTwinCreationMetadataStatus.toBeBurned:
        return context.loc.nftCreationsPageToBeBurned;
      case DigitalTwinCreationMetadataStatus.toBeTransferred:
        return context.loc.nftCreationsPageToBeTransferred;
    }
  }

  Widget _buildFooter(
    BuildContext context,
    LoadStatus? loadStatus, {
    bool error = false,
  }) {
    return SizedBox(
      height: 55.0,
      child: Center(
        child: Column(
          children: [
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: child,
                  );
                },
                child: loadStatus == LoadStatus.loading
                    ? CircularProgressIndicator(
                        color: CustomColors(dotenv.get("APP_ID")).primaryColor,
                      )
                    : Icon(
                        Icons.arrow_upward,
                        color: CustomColors(dotenv.get("APP_ID")).primaryColor,
                      )),
            Text(
              loadStatus == LoadStatus.loading
                  ? context.loc.nftCreationsPageLoading
                  : context.loc.nftCreationsPagePullToLoadMore,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (mode == RefreshStatus.refreshing)
                  CircularProgressIndicator(
                    color: CustomColors(dotenv.get("APP_ID")).primaryColor,
                  )
                else
                  Icon(
                    Icons.arrow_downward,
                    color: CustomColors(dotenv.get("APP_ID")).primaryColor,
                  ),
                const SizedBox(
                  width: 16,
                ),
                Text(
                  mode == RefreshStatus.refreshing
                      ? context.loc.nftCreationsPageRefreshing
                      : context.loc.nftCreationsPagePullToRefresh,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _scanItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata, {
    Function(String)? onTokenExist,
  }) async {
    final res = await scanItem(
      ref,
      context,
      navigateToResultPage: true,
      navigateToTokenDoesNotExistPage: false,
      navigateToTokenExistsPage:
          metadata.status != DigitalTwinCreationMetadataStatus.pending,
      returnOnTokenExists: true,
      onTokenExists: onTokenExist,
    );

    if (res == null) {
      return false;
    }

    final chipInfo = ref.read(chipInfoProvider);

    if ([
      DigitalTwinCreationMetadataStatus.toBeBurned,
      DigitalTwinCreationMetadataStatus.toBeTransferred,
    ].contains(metadata.status)) {
      if (chipInfo.chipEthereumAddress.hex != metadata.tokenId) {
        ScaffoldMessenger.of(context).showSnackBar(returnSnackBarWidget(
            context.loc.nftCreationsPageError,
            context.loc.nftCreationsPageChipMismatchError,
            'error'));

        return false;
      }
    }

    return true;
  }

  Future<void> _burnItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata,
  ) async {
    if (await _scanItem(context, creations, metadata)) {
      final userSession = ref.read(userSessionProvider)!;
      final wc = ref.read(w3mServiceProvider);

      final tokenId = BigInt.parse(metadata.tokenId!);

      await burnToken(
        wc,
        tokenId,
        ref.read(chipSignatureDataProvider),
        userSession.userWalletAddress,
        digitalTwinMetadata: metadata,
      );
    }
  }

  Future<void> _mintItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata,
  ) async {
    if (await _scanItem(
      context,
      creations,
      metadata,
      onTokenExist: (String tokenId) {
        showCustomPopup(
          context,
          context.loc.nftCreationRestoreTokenPopupTitle,
          RestoreTokenPopup(
            metadata: metadata,
            tokenId: tokenId,
          ),
        ).then((res) {
          if (res != true) {
            return;
          }
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   returnSnackBarWidget(
        //     context.loc.warning,
        //     context.loc.nftCreationsAlreadyMintedToken,
        //     "warning",
        //     duration: const Duration(
        //       seconds: 6,
        //     ),
        //   ),
        // );
      },
    )) {
      final userSession = ref.read(userSessionProvider)!;
      final wc = ref.read(w3mServiceProvider);

      await createToken(
        userSession.sessionId,
        wc!,
        ref.read(chipSignatureDataProvider),
        metadata,
      );
    }
  }

  Future<void> _transferItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata,
  ) async {
    if (await _scanItem(context, creations, metadata)) {
      Navigator.pushNamed(context, TransferScreen.routeName,
          arguments: TransferScreenArguments(
            digitalTwinMetadata: metadata,
          ));
    }
  }
}
