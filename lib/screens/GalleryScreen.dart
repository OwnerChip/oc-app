//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/constants.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/widgets/popups/WalletPopUp.dart';

//import widgets
import 'package:ownerchip_whitelabel/widgets/layout/ScreenBodyLayout.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomAppBar.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';

//import misc
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/GalleryItem.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  context.loc.youDoNotOwnAnyItems,
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
                  return GalleryItem(
                    item: item,
                    ref: ref,
                  );
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
                  context.loc.pleaseConnectWalletToViewItems,
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
                  return GalleryItem(
                    item: item,
                    ref: ref,
                  );
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
                  context.loc.pleaseConnectWalletToViewItems,
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
      appBar: CustomAppBar(
        showBackButton: true,
        text: context.loc.myCollection,
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
            label: context.loc.ownedByMe,
          ),
          BottomNavigationBarItem(
            icon: Container(),
            label: context.loc.createdByMe,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: CustomColors(dotenv.get('APP_ID')).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
