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
                    DigitalTwinCreationType.single) {
                  return _buildSingleTwin(metadata, context, creations);
                } else if (metadata.type ==
                    DigitalTwinCreationType.multiple) {
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
    final numberOfTokens = metadata.totalActiveSeriesItems ?? 0;
    final quantity = metadata.quantity ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
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
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (metadata.imageLink != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Image.network(
                          metadata.imageLink!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleWithSerialRange(context, metadata),
                        const SizedBox(height: 6),
                          Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.loc.nftCreationMultiSeriesBadge,
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.loc.nftCreationMultiSeriesItemsCount(numberOfTokens.toString()),
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getSeriesStatusText(context, metadata.status),
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getSeriesActionText(context, metadata.status),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (numberOfTokens > 0 && numberOfTokens < quantity) ...[
                          const SizedBox(height: 6),
                          Text(
                            context.loc.nftCreationMultiSeriesItemsActivated(
                              numberOfTokens.toString(),
                              quantity.toString(),
                            ),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (metadata.id == _selectedCreationId) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.loc.nftCreationMultiSeriesTitle),
                    const SizedBox(height: 8),
                    Text(context.loc.nftCreationMultiSeriesStatus(
                        numberOfTokens.toString(), quantity.toString())),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final width = MediaQuery.of(context).size.width - 64;
                        final progress =
                            quantity > 0 ? numberOfTokens / quantity : 0.0;

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
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.maxFinite,
                        child: CustomRoundedButton(
                            text: context
                                .loc.nftCreationMultiSeriesActivateButton,
                            onPressed: () => _mintNextSeriesItem(
                              context,
                              creations,
                              metadata,
                            ))),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.maxFinite,
                      child: CustomOutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCreationId = null;
                            });
                          },
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

  String _getSeriesStatusText(
      BuildContext context, DigitalTwinCreationMetadataStatus status) {
    switch (status) {
      case DigitalTwinCreationMetadataStatus.pending:
        return context.loc.nftCreationSeriesStatusActivationPending;
      case DigitalTwinCreationMetadataStatus.draft:
        return context.loc.nftCreationSeriesStatusDraft;
      case DigitalTwinCreationMetadataStatus.minted:
        return context.loc.nftCreationSeriesStatusActive;
      case DigitalTwinCreationMetadataStatus.toBeBurned:
        return context.loc.nftCreationSeriesStatusToBeBurned;
      case DigitalTwinCreationMetadataStatus.toBeTransferred:
        return context.loc.nftCreationSeriesStatusToBeTransferred;
      default:
        return context.loc.nftCreationSeriesStatusActive;
    }
  }

  Widget _buildTitleWithSerialRange(BuildContext context, DigitalTwinMetadata metadata) {
    final title = metadata.title;
    final serialStart = metadata.serialStartNumber;
    final quantity = metadata.quantity ?? 0;

    // Check if title contains the template placeholder
    if (title.contains('#[{SERIAL}]') && serialStart != null && quantity > 0) {
      final serialEnd = serialStart + quantity - 1;
      final serialRange = '$serialStart-$serialEnd';
      
      // Split the title by the template
      final parts = title.split('#[{SERIAL}]');
      
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black,
              ),
          children: [
            if (parts.isNotEmpty) TextSpan(text: parts[0]),
            TextSpan(
              text: serialRange,
              style: TextStyle(
                color: CustomColors(dotenv.get("APP_ID")).primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    }

    // Fallback to regular text if no template found
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getSeriesActionText(
      BuildContext context, DigitalTwinCreationMetadataStatus status) {
    switch (status) {
      case DigitalTwinCreationMetadataStatus.pending:
        return context.loc.nftCreationSeriesActionStartScanning;
      default:
        return context.loc.nftCreationSeriesActionConnectNFC;
    }
  }

  void _showCancelDialog(BuildContext context, DigitalTwinMetadata metadata) {
    String title = "";
    String description = "";
    String yes = "";
    String cancel = "";
    VoidCallback onYes = () {};

    if (metadata.status == DigitalTwinCreationMetadataStatus.toBeBurned) {
      onYes = () {
        BackendCreationService.instance.cancelBurnDigitalTwin(metadata.id);
      };
      title = context.loc.nft_burn_cancel_confirmation_dialog_title;
      description = context.loc
          .nft_burn_cancel_confirmation_dialog_description(metadata.title);
      yes = context.loc
          .nft_burn_cancel_confirmation_dialog_cancel_cancel_button;
      cancel =
          context.loc.nft_burn_cancel_confirmation_dialog_cancel_keep_button;
    } else if (metadata.status == DigitalTwinCreationMetadataStatus.pending) {
      onYes = () {
        BackendCreationService.instance.cancelDigitalTwin(metadata.id);
      };
      title = context.loc.nft_cancel_confirmation_dialog_title;
      description =
          context.loc.nft_cancel_confirmation_dialog_description(metadata.title);
      yes = context.loc.nft_cancel_confirmation_dialog_cancel_cancel_button;
      cancel = context.loc.nft_cancel_confirmation_dialog_cancel_keep_button;
    } else if (metadata.status ==
        DigitalTwinCreationMetadataStatus.toBeTransferred) {
      onYes = () {
        BackendCreationService.instance.cancelTransferDigitalTwin(metadata.id);
      };
      title = context.loc.nft_transfer_cancel_confirmation_dialog_title;
      description = context.loc
          .nft_transfer_cancel_confirmation_dialog_description(metadata.title);
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
  }

  Widget _buildSingleTwin(DigitalTwinMetadata metadata, BuildContext context,
      CreationsData creations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          _onTapSingle(metadata, context, creations);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (metadata.imageLink != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.network(
                      metadata.imageLink!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.loc.nftCreationSingleItemBadge,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_getTextByStatus(context, metadata.status).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(metadata.status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getTextByStatus(context, metadata.status),
                              style: TextStyle(
                                color: _getStatusTextColor(metadata.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getSingleActionText(context, metadata.status),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_shouldShowCancelButton(metadata.status))
                InkWell(
                  onTap: () {
                    _showCancelDialog(context, metadata);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowCancelButton(DigitalTwinCreationMetadataStatus status) {
    return [
      DigitalTwinCreationMetadataStatus.pending,
      DigitalTwinCreationMetadataStatus.toBeBurned,
      DigitalTwinCreationMetadataStatus.toBeTransferred,
    ].contains(status);
  }

  Color _getStatusColor(DigitalTwinCreationMetadataStatus status) {
    switch (status) {
      case DigitalTwinCreationMetadataStatus.pending:
        return Colors.blue.withOpacity(0.1);
      case DigitalTwinCreationMetadataStatus.toBeBurned:
        return Colors.red.withOpacity(0.1);
      case DigitalTwinCreationMetadataStatus.toBeTransferred:
        return Colors.orange.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(DigitalTwinCreationMetadataStatus status) {
    switch (status) {
      case DigitalTwinCreationMetadataStatus.pending:
        return Colors.blue[700]!;
      case DigitalTwinCreationMetadataStatus.toBeBurned:
        return Colors.red[700]!;
      case DigitalTwinCreationMetadataStatus.toBeTransferred:
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getSingleActionText(
      BuildContext context, DigitalTwinCreationMetadataStatus status) {
    switch (status) {
      case DigitalTwinCreationMetadataStatus.pending:
        return context.loc.nftCreationSingleActionConnectNFC;
      case DigitalTwinCreationMetadataStatus.toBeBurned:
        return context.loc.nftCreationSingleActionBurnToken;
      case DigitalTwinCreationMetadataStatus.toBeTransferred:
        return context.loc.nftCreationSingleActionTransferToken;
      default:
        return context.loc.nftCreationSingleActionConnectNFC;
    }
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

  Future<void> _mintNextSeriesItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata,
  ) async {
    if (await _scanItem(
      context,
      creations,
      metadata,
      onTokenExist: (String tokenId) {},
    )) {
      final userSession = ref.read(userSessionProvider)!;
      final wc = ref.read(w3mServiceProvider);

      // Use the parent metadata for MULTI_SERIAL_ITEM minting
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
