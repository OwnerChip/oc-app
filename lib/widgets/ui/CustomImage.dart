import 'package:flutter/material.dart';
import 'dart:io';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CustomImage extends StatelessWidget {
  const CustomImage(
      {super.key,
      this.imagePath,
      this.imageFile,
      this.width,
      this.height,
      this.loading = true,
      this.tokenId,
      this.boxFit = BoxFit.contain,
      this.aspectRatio = null,
      this.decoration,
      this.imageBorderRadius = 19.0});

  final dynamic imagePath;
  final dynamic imageFile;
  final double? width;
  final double? height;
  final bool loading;
  final BigInt? tokenId;
  final BoxFit boxFit;
  final double? aspectRatio;
  final BoxDecoration? decoration;
  final double imageBorderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: decoration ??
            BoxDecoration(
                color: CustomColors(dotenv.get('APP_ID')).secondaryColor,
                borderRadius: BorderRadius.circular(19),
                boxShadow: [
                  BoxShadow(
                      color: CustomColors(dotenv.get('APP_ID'))
                          .secondaryShadowColor,
                      blurRadius: 5,
                      offset: const Offset(3, 2)),
                ]),
        child: Stack(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(imageBorderRadius),
              child: Builder(builder: (context) {
                final child = loading || imagePath == null || imagePath == ""
                    ? Image.asset(
                        '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg',
                        fit: BoxFit.cover,
                      )
                    : imageFile != null
                        ? Image.file(
                            File(imagePath),
                            fit: boxFit,
                          )
                        : Image.network(imagePath,
                            fit: boxFit,
                            frameBuilder: (context, child, frame,
                                    wasSynchronouslyLoaded) =>
                                wasSynchronouslyLoaded
                                    ? child
                                    : AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration:
                                            const Duration(milliseconds: 700),
                                        curve: Curves.easeOut,
                                        child: child,
                                      ));

                return aspectRatio != null
                    ? AspectRatio(
                        aspectRatio: aspectRatio!,
                        child: child,
                      )
                    : child;
              })),
        ]));
  }
}
