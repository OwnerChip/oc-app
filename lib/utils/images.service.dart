import 'package:image_picker/image_picker.dart';

Future<XFile?> getImageFromCamera() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 30,
      maxHeight: 500,
      maxWidth: 500);
  return photo;
}

Future<XFile?> getImageFromGallery() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxHeight: 500,
      maxWidth: 500);
  return image;
}
