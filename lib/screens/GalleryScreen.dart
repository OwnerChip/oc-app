//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/screens/NFTDetailsScreen.dart';
import 'package:ownerchip_whitelabel/services/nfc.services.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/utils.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';
import 'package:ownerchip_whitelabel/widgets/popups/returnSnackBarWidget.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/config/moreInfoButtons.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  static const routeName = '/gallery';

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List?> ownedOcNfts = ref.watch(getOcNftsForOwner);
    final AsyncValue<List?> mintedOcNfts = ref.watch(getOcNftsMintedByUser);
    final UserSession? userSession = ref.watch(userSessionProvider);

    List<Widget> _widgetOptions = <Widget>[
      ownedOcNfts.when(
          data: (data) {
            if (data!.length == 0) {
              return Column(children: [
                const SizedBox(height: 20),
                Text(
                  'You do not own any items.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]);
            } else {
              return Expanded(
                  // Provides bounded constraints for the GridView
                  child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 0.95,
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 12.0, // Horizontal space between items
                  mainAxisSpacing: 12.0, // Vertical space between items
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  Map item = data[index];
                  return GestureDetector(
                      onTap: () {
                        final BigInt chipTokenId =
                            BigInt.parse(item['tokenId']);
                        final EthereumAddress chipEthereumAddress =
                            EthereumAddress.fromHex(
                                convertTokenIdToEthereumAddress(chipTokenId));
                        setChipInfoProvider(
                            ref, chipEthereumAddress, chipTokenId);

                        Navigator.of(context)
                            .pushNamed(NFTDetailsScreen.routeName);
                      },
                      child: CustomCard(
                          padding: const EdgeInsets.all(11),
                          borderRadius: 19,
                          children: [
                            CustomImage(
                              loading: false,
                              imagePath: item['image']['thumbnailUrl'],
                              boxFit: BoxFit.cover,
                              aspectRatio: 1,
                            ),
                            Text(
                                item['name'].length > 10
                                    ? '${item['name'].substring(0, 10)}...'
                                    : item['name'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .accentColor)),
                          ]));
                },
              ));
            }
          },
          error: (e, s) {
            if (userSession == null ||
                userSession.userWalletAddress == zeroAddress) {
              return Column(children: [
                const SizedBox(height: 20),
                Text(
                  'Please connect your wallet to view items.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                CustomRoundedButton(
                    width: 250,
                    text: context.loc.connectWallet,
                    onPressed: (() => {walletPopupBuilder(context, ref)}))
              ]);
            } else {
              return Container();
            }
          },
          loading: () => CircularProgressIndicator(
              color: CustomColors(dotenv.get('APP_ID')).primaryColor)),
      mintedOcNfts.when(
          data: (data) {
            if (data!.length == 0) {
              return Column(children: [
                const SizedBox(height: 20),
                Text(
                  'You have not minted any items.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]);
            } else {
              return Expanded(
                  // Provides bounded constraints for the GridView
                  child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 0.95,
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 12.0, // Horizontal space between items
                  mainAxisSpacing: 12.0, // Vertical space between items
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  Map item = data[index];
                  if (item['name'] == null) {
                    return Container();
                  }
                  return GestureDetector(
                      onTap: () {
                        final BigInt chipTokenId =
                            BigInt.parse(item['tokenId']);
                        final EthereumAddress chipEthereumAddress =
                            EthereumAddress.fromHex(
                                convertTokenIdToEthereumAddress(chipTokenId));
                        setChipInfoProvider(
                            ref, chipEthereumAddress, chipTokenId);

                        Navigator.of(context)
                            .pushNamed(NFTDetailsScreen.routeName);
                      },
                      child: CustomCard(
                          padding: const EdgeInsets.all(11),
                          borderRadius: 19,
                          children: [
                            CustomImage(
                              loading: false,
                              imagePath: item['image']['thumbnailUrl'],
                              boxFit: BoxFit.cover,
                              aspectRatio: 1,
                            ),
                            Text(
                                item['name'].length > 10
                                    ? '${item['name'].substring(0, 10)}...'
                                    : item['name'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                        color:
                                            CustomColors(dotenv.get('APP_ID'))
                                                .accentColor)),
                          ]));
                },
              ));
            }
          },
          error: (e, s) {
            if (userSession == null ||
                userSession.userWalletAddress == zeroAddress) {
              return Column(children: [
                const SizedBox(height: 20),
                Text(
                  'Please connect your wallet to view items.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                CustomRoundedButton(
                    width: 250,
                    text: context.loc.connectWallet,
                    onPressed: (() => {walletPopupBuilder(context, ref)}))
              ]);
            } else {
              return Container();
            }
          },
          loading: () => CircularProgressIndicator(
              color: CustomColors(dotenv.get('APP_ID')).primaryColor)),
    ];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        showBackButton: true,
      ),
      body: ScreenBodyLayout(
        withScrollView: false,
        mainAxisAlignment: MainAxisAlignment.center,
        flexSides: 0,
        padding: const EdgeInsets.only(top: 0, bottom: 15),
        children: [_widgetOptions.elementAt(_selectedIndex)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Container(),
            label: 'Owned by me',
          ),
          BottomNavigationBarItem(
            icon: Container(),
            label: 'Created by me',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: CustomColors(dotenv.get('APP_ID')).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
