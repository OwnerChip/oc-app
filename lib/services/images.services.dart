import 'package:image_picker/image_picker.dart';

Future<XFile?> getImageFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxHeight: 900,
      maxWidth: 900);
  return photo;
}

Future<XFile?> getImageFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxHeight: 900,
      maxWidth: 900);
  return image;
}

Future<XFile?> getMediaFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? media = await picker.pickMedia();
  return media;
}
