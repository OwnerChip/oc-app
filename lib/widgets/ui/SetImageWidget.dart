//import packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
//import CustomColors
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
//import utils
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';

import 'CustomCard.dart';
//import widgets
import 'CustomImage.dart';
import 'CustomRoundedButton.dart';

class SetImageWidget extends ConsumerStatefulWidget {
  const SetImageWidget(
      {Key? key,
      this.imageFile,
      required this.setCameraImage,
      required this.setGalleryImage,
      required this.resetImage})
      : super(key: key);

  final XFile? imageFile;
  final Function setCameraImage;
  final Function setGalleryImage;
  final Function resetImage;

  @override
  _SetImageWidgetState createState() => _SetImageWidgetState();
}

class _SetImageWidgetState extends ConsumerState<SetImageWidget> {
  bool showImageOptions = false;
  String imagePath = '${dotenv.get('IMAGE_ASSETS_BASE_URL')}/placeholder.jpg';

  void cameraImageButtonPress() async {
    XFile imageFile = await widget.setCameraImage();
    setState(() {
      showImageOptions = false;
      imagePath = imageFile.path;
    });
  }

  void galleryImageButtonPress() async {
    XFile imageFile = await widget.setGalleryImage();
    setState(() {
      showImageOptions = false;
      imagePath = imageFile.path;
    });
  }

  void onCameraButtonPressed() {
    setState(() {
      showImageOptions = true;
    });
  }

  //build method
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: widget.imageFile != null
          ? GestureDetector(
              onTap: () {
                widget.resetImage();
                setState(() {
                  showImageOptions = true;
                });
              },
              child: CustomImage(
                loading: false,
                imagePath: imagePath,
                imageFile: widget.imageFile,
              ),
            )
          : CustomCard(
              color: Theme.of(context).scaffoldBackgroundColor,
              mainAxisAlignment: MainAxisAlignment.center,
              width: double.infinity,
              children: [
                  showImageOptions
                      ? Column(
                          children: [
                            CustomRoundedButton(
                                mainAxisAlignment: MainAxisAlignment.start,
                                icon: Icon(Icons.camera_alt_outlined,
                                    color: CustomColors(dotenv.get('APP_ID'))
                                        .metadataImagePickerIconsColor),
                                width: 180,
                                text: context.loc.takePicture,
                                onPressed: cameraImageButtonPress),
                            const SizedBox(height: 10),
                            CustomRoundedButton(
                                mainAxisAlignment: MainAxisAlignment.start,
                                icon: Icon(Icons.image_outlined,
                                    color: CustomColors(dotenv.get('APP_ID'))
                                        .metadataImagePickerIconsColor),
                                width: 180,
                                text: context.loc.selectImage,
                                onPressed: galleryImageButtonPress),
                          ],
                        )
                      : IconButton(
                          iconSize: 50,
                          icon: const Icon(Icons.camera_alt_outlined),
                          color: Theme.of(context).primaryColorLight,
                          onPressed: onCameraButtonPressed,
                        ),
                ]),
    );
  }
}
