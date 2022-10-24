import 'package:image_picker/image_picker.dart';

Future<XFile?> getImageFromCamera() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxHeight: 1280,
      maxWidth: 960);
  return photo;
}

Future<XFile?> getImageFromGallery() async {
  final ImagePicker _picker = ImagePicker();
  final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxHeight: 1280,
      maxWidth: 960);
  return image;
}
