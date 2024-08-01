import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/screens/TransferScreen.dart';
import 'package:ownerchip_whitelabel/screens/nftActionsScreenMixin.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/chipData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsData.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/globals.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/popups/CustomOverlay.dart';
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
          key: ScaffoldKey.getScaffoldKey('CreationsPage'),
          appBar: CustomAppBar(
            text: context.loc.nftCreationsPageTitle,
          ),
          body: SmartRefresher(
            enablePullDown: true,
            enablePullUp: false,
            controller: _refreshController,
            onRefresh: () async {
              await ref.read(creationsNotifierProvider.notifier).init();
              _refreshController.refreshCompleted();
            },
            header: CustomHeader(
              builder: (context, mode) => _buildHeader(context, mode: mode),
            ),
            child: ListView.builder(
              itemCount: creations.data!.data.length,
              itemBuilder: (context, index) {
                final metadata = creations.data!.data[index];
                return InkWell(
                  onTap: () {
                    if (metadata.status ==
                        DigitalTwinCreationMetadataStatus.toBeBurned) {
                      _burnItem(
                        context,
                        creations,
                        metadata,
                      );
                    } else if (metadata.status ==
                        DigitalTwinCreationMetadataStatus.pending) {
                      _mintItem(
                        context,
                        creations,
                        metadata,
                      );
                    } else if (metadata.status ==
                        DigitalTwinCreationMetadataStatus.toBeTransferred) {
                      _transferItem(context, metadata);
                    }
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
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          )),
    );
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

  Future<void> _burnItem(
    BuildContext context,
    CreationsData creations,
    DigitalTwinMetadata metadata,
  ) async {
    final res = await scanItem(
      ref,
      context,
      navigateToResultPage: false,
    );

    if (res != null) {
      final userSession = ref.read(userSessionProvider)!;
      final wc = ref.read(wcProvider);

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
    final res = await scanItem(
      ref,
      context,
      navigateToResultPage: false,
    );
    if (res != null) {
      final userSession = ref.read(userSessionProvider)!;
      final wc = ref.read(wcProvider);

      createToken(
        userSession.sessionId,
        wc!,
        ref.read(chipSignatureDataProvider),
        metadata,
      );
    }
  }

  Future<void> _transferItem(
      BuildContext context, DigitalTwinMetadata metadata) async {
    final res = await scanItem(
      ref,
      context,
      navigateToResultPage: false,
    );
    if (res != null) {
      Navigator.pushNamed(context, TransferScreen.routeName,
          arguments: TransferScreenArguments(
            digitalTwinMetadata: metadata,
          ));
    }
  }
}
