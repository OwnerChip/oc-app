import 'package:flutter/material.dart';
import 'dart:io';
import 'SmallTextContainer.dart';

class CustomImage extends StatelessWidget {
  CustomImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.loading = true,
    this.tokenId,
  });

  final dynamic? imagePath;
  final double? width;
  final double? height;
  final bool loading;
  final BigInt? tokenId;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            boxShadow: const [
              BoxShadow(
                  color: Color.fromARGB(50, 0, 0,
                      21), //TODO: externalize color (not sure where to, there is only one shadow color in theme??)
                  blurRadius: 5,
                  offset: Offset(3, 2)),
            ]),
        child: Stack(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: AspectRatio(
                aspectRatio: 0.75,
                child: loading || imagePath == null
                    ? Image.asset(
                        'assets/images/placeholder.jpg',
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
              )),
          tokenId != null
              ? AspectRatio(
                  aspectRatio: 0.75,
                  child: Align(
                    alignment: const Alignment(-1.0, 0.95),
                    child:
                        //container with rounded corners and text inside
                        Row(children: [
                      //spacing
                      const SizedBox(width: 5),
                      const SmallTextContainer(
                        text: 'Token ID',
                      ),
                      const SizedBox(width: 10),
                      SmallTextContainer(
                        text: '${tokenId.toString().substring(0, 8)}...',
                      ),
                    ]),
                  ))
              : Container()
        ]));
  }
}
