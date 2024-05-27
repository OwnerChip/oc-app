import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/appBar/CustomAppBar.dart';

class MyBalancePage extends StatelessWidget {
  const MyBalancePage({super.key});

  static const String routeName = '/myBalance';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: const Center(
        child: Text('My Balance Page'),
      ),
    );
  }
}
