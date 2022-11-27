import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../utils/localization.helper.dart';

//local imports
import 'NFTDetailsScreen.dart';
import '../widgets/CustomAppBar.dart';
import '../utils/navigation_arguments.dart';
import '../widgets/ChipInfo.dart';
import '../widgets/CustomCard.dart';
import '../widgets/CustomCard.dart';
import '../widgets/ScreenBodyLayout.dart';
import '../widgets/CustomImage.dart';
import '../widgets/SmallTextContainer.dart';
import '../widgets/CustomRoundedButton.dart';

class UserScanResultsScreen extends StatelessWidget {
  const UserScanResultsScreen(
      {super.key,
      required this.connector,
      this.loginWithMetaMask,
      required this.connected});
  final WalletConnect connector;
  final Function? loginWithMetaMask;
  final bool connected;

  static const routeName = '/user-scan-results';

  Future<void> launchWallet() async {
    await launchUrlString('wc:', mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final navArgs = ModalRoute.of(context)!.settings.arguments
        as UserScanResultsScreenArguments;

    final connectedWallet = connector.session.accounts.length > 0
        ? connector.session.accounts[0].toLowerCase()
        : '';

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CustomAppBar(
          loginFunction: loginWithMetaMask,
          text: context.loc.tapResults,
          connectedWallet: connected ? null : connectedWallet,
          connector: connector,
          connected: connected,
        ),
        body: ScreenBodyLayout(children: [
          Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomCard(
                  margin: EdgeInsets.only(top: 70),
                  width: double.infinity,
                  children: [
                    SizedBox(height: 100),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        //Header Title
                        connected && connectedWallet == navArgs.nftOwner
                            ?
                            //connected wallet is owner
                            Text(context.loc.congrats,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline1)
                            :
                            //connected wallet is not owner
                            Text(context.loc.whoops,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline1),

                        SizedBox(height: 15),

                        //Header Body Text
                        !navArgs.chipIsInitialized
                            ?
                            //chip is not initialized aka NFT does not exist
                            Text(context.loc.nftNotFound,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyText1)
                            : connected && connectedWallet == navArgs.nftOwner
                                ?
                                //chip is initialized and wallet is connected
                                Text(context.loc.authenticityNftFound,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.bodyText1)
                                :
                                //chip is initialized and wallet is NOT connected
                                Container()
                      ],
                    ),
                    SizedBox(height: 15),
                    CustomCard(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.loc.authenticityCheck,
                              style: Theme.of(context).textTheme.headline2),

                          //Ownerchip Check Icon
                          !navArgs.chipIsInitialized
                              ? //chip not initialized aka no NFT exists
                              const Icon(
                                  Icons.cancel,
                                  color: Colors
                                      .orange, //TODO externalize orange as warning color to Theme
                                  size: 36,
                                )
                              : !connected
                                  ?
                                  //chip is initialized and wallet is NOT connected
                                  const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors
                                          .orange, //TODO externalize orange as warning color to Theme
                                      size: 36,
                                    )
                                  : connectedWallet == navArgs.nftOwner
                                      ?
                                      //chip is initialized and wallet is connected and wallet is owner
                                      Icon(
                                          Icons.check_circle,
                                          color: Theme.of(context)
                                              .primaryColorLight,
                                          size: 36,
                                        )
                                      :
                                      //chip is initialized and wallet is connected and wallet is NOT owner
                                      const Icon(
                                          Icons.cancel,
                                          color: Colors.orange,
                                          size: 36,
                                        )
                        ],
                      ),
                      //spacing
                      SizedBox(height: 15),

                      //Ownerchip Check Icon
                      !navArgs.chipIsInitialized
                          ? //chip not initialized aka no NFT exists
                          Text(context.loc.youAreNotNftOwner,
                              style: Theme.of(context).textTheme.bodyText1)
                          : !connected
                              ?
                              //chip is initialized and wallet is NOT connected
                              Text(context.loc.noWalletConnected,
                                  style: Theme.of(context).textTheme.bodyText1)
                              : connectedWallet == navArgs.nftOwner
                                  ?
                                  //chip is initialized and wallet is connected and wallet is owner
                                  Text(context.loc.youAreNftOwner,
                                      style:
                                          Theme.of(context).textTheme.bodyText1)
                                  :
                                  //chip is initialized and wallet is connected and wallet is NOT owner
                                  Text(context.loc.youAreNotNftOwner,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyText1),

                      SizedBox(height: 15),

                      //Ownerchip Check Button
                      !navArgs.chipIsInitialized
                          ?
                          //chip is NOT initialized
                          Container()
                          : !connected
                              ?
                              //chip is initialized and wallet is NOT connected
                              CustomRoundedButton(
                                  text: context.loc.connectWallet,
                                  onPressed: (() =>
                                      {loginWithMetaMask!(context)}))
                              :
                              //chip is initialized and wallet is connected
                              CustomRoundedButton(
                                  text: context.loc.viewNftDetails,
                                  onPressed: () {
                                    print(context);
                                    Navigator.of(context).pushNamed(
                                        NFTDetailsScreen.routeName,
                                        arguments: NFTDetailsScreenArguments(
                                            loginWithMetaMask,
                                            navArgs.tokenId,
                                            navArgs.chipWalletAddress,
                                            ""));
                                  }),
                    ]),
                    //spacing
                    SizedBox(height: 20),
                    CustomCard(children: [
                      Row(
                        //space between
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.loc.nfcCheck,
                              style: Theme.of(context).textTheme.headline2),
                          //checkmark icon
                          Icon(Icons.check_circle,
                              size: 36,
                              color: Theme.of(context).primaryColorLight),
                        ],
                      ),
                      //spacing
                      SizedBox(height: 15),
                      ChipInfo(
                          tokenId: navArgs.chipIsInitialized
                              ? navArgs.tokenId
                              : null,
                          chipName: 'Infineon Secora',
                          walletAddress: navArgs.chipWalletAddress)
                    ])
                  ]),
              CustomImage(
                width: 130,
                loading: true,
                imagePath: '',
              ),
            ],
          ),
        ])

        //  SafeArea(
        //     child: Center(
        //   child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        //     Row(
        //       children: [
        //         Expanded(
        //             flex: 3,
        //             child: Row(
        //                 mainAxisAlignment: MainAxisAlignment.end,
        //                 children: [
        //                   navArgs.chipIsInitialized
        //                       ? const Icon(
        //                           Icons.check_circle,
        //                           color: Colors.green,
        //                           size: 44,
        //                         )
        //                       : const Icon(
        //                           Icons.cancel,
        //                           color: Colors.red,
        //                           size: 44,
        //                         ),
        //                   const SizedBox(width: 10),
        //                 ])),
        //         const SizedBox(height: 100),
        //         Expanded(
        //             flex: 7,
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Text('${context.loc.nftCheck}: ',
        //                     style: TextStyle(fontSize: 18)),
        //                 const SizedBox(height: 15),
        //                 navArgs.chipIsInitialized
        //                     ? Column(
        //                         crossAxisAlignment: CrossAxisAlignment.start,
        //                         children: [
        //                           ChipInfo(
        //                               tokenId: navArgs.tokenId,
        //                               chipName: 'Secora Infineon',
        //                               walletAddress: navArgs.chipWalletAddress),
        //                           //button that navigates to nft details screen
        //                           OutlinedButton(
        //                               style: OutlinedButton.styleFrom(
        //                                 foregroundColor:
        //                                     Theme.of(context).primaryColor,
        //                               ),
        //                               onPressed: () {
        //                                 print(context);
        //                                 Navigator.of(context).pushNamed(
        //                                     NFTDetailsScreen.routeName,
        //                                     arguments:
        //                                         NFTDetailsScreenArguments(
        //                                             loginWithMetaMask,
        //                                             navArgs.tokenId,
        //                                             navArgs.chipWalletAddress,
        //                                             ""));
        //                               },
        //                               child: Text(context.loc.viewNftDetails))
        //                         ],
        //                       )
        //                     : Text(context.loc.nftNotFound,
        //                         style: TextStyle(fontSize: 14)),
        //               ],
        //             )),
        //       ],
        //     ),
        //     //spacing
        //     const SizedBox(height: 40),
        //     Row(
        //       children: [
        //         Expanded(
        //             flex: 3,
        //             child: Row(
        //                 mainAxisAlignment: MainAxisAlignment.end,
        //                 children: [
        //                   connector.session.accounts.isEmpty
        //                       ? //no wallet connected
        //                       const Icon(
        //                           Icons.warning_amber_rounded,
        //                           color: Colors.orange,
        //                           size: 44,
        //                         )
        //                       : connector?.session.accounts[0].toLowerCase() ==
        //                               navArgs.nftOwner
        //                           ? //you are the owner
        //                           const Icon(
        //                               Icons.check_circle,
        //                               color: Colors.green,
        //                               size: 44,
        //                             )
        //                           : const Icon(
        //                               Icons.cancel,
        //                               color: Colors.red,
        //                               size: 44,
        //                             ),
        //                   const SizedBox(width: 10),
        //                 ])),
        //         Expanded(
        //             flex: 7,
        //             child: Column(
        //               crossAxisAlignment: CrossAxisAlignment.start,
        //               children: [
        //                 Text('${context.loc.checkOwner}: ',
        //                     style: const TextStyle(fontSize: 18)),
        //                 const SizedBox(height: 15),
        //                 connector.session.accounts.isEmpty
        //                     ? Column(
        //                         crossAxisAlignment: CrossAxisAlignment.start,
        //                         children: [
        //                           Text(context.loc.noWalletConnected,
        //                               style: TextStyle(fontSize: 14)),
        //                           const SizedBox(height: 3),
        //                           connector.session.accounts.isEmpty
        //                               ? OutlinedButton(
        //                                   style: OutlinedButton.styleFrom(
        //                                     foregroundColor:
        //                                         Theme.of(context).primaryColor,
        //                                   ),
        //                                   onPressed: (() => {
        //                                         loginWithMetaMask!(context),
        //                                       }),
        //                                   child:
        //                                       Text(context.loc.connectWallet))
        //                               : Container()
        //                         ],
        //                       )
        //                     : connector?.session.accounts[0].toLowerCase() ==
        //                             navArgs.nftOwner
        //                         ? Column(
        //                             crossAxisAlignment:
        //                                 CrossAxisAlignment.start,
        //                             children: [
        //                               Text(context.loc.youAreNftOwner,
        //                                   style: TextStyle(fontSize: 14)),
        //                             ],
        //                           )
        //                         : Text(context.loc.noNftInWallet,
        //                             style: TextStyle(fontSize: 14)),
        //               ],
        //             )),
        //       ],
        //     ),
        //     const SizedBox(height: 100),
        //     SizedBox(
        //         width: 200,
        //         height: 50,
        //         child: ElevatedButton(
        //             style: ElevatedButton.styleFrom(
        //               backgroundColor: Colors.grey, // background
        //             ),
        //             onPressed: () =>
        //                 {Navigator.pushReplacementNamed(context, '/login')},
        //             child: Text(context.loc.home)))
        //   ]),
        // ))
        );
  }
}
