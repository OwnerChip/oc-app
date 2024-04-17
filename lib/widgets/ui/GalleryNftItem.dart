//insert flutter widget boilerplate
import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomImage.dart';

class GalleryNftItem extends StatelessWidget {
  const GalleryNftItem({
    super.key,
    this.loading = true,
    this.imagePath,
  });

  final bool loading;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return CustomCard(children: [
      CustomImage(
        loading: false,
        imagePath: imagePath,
      ),
    ]);
  }
}
