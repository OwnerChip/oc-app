import 'dart:io';

void main(List<String> arguments) async {
  // Get the file names from the command line arguments
  var args = List<String>.from(arguments);
  if (args.length != 2) {
    print('Usage: dart replace_file.dart source_file target_file');
    exit(1);
  }
  var sourceFile = args[0];
  var targetFile = args[1];

  // Read the content of the source file
  var sourceContent = await File(sourceFile).readAsString();

  // Write the content to the target file, overwriting any existing content
  await File(targetFile).writeAsString(sourceContent);

  // Print a confirmation message
  print(
      'The content of $sourceFile has been replaced with the content of $targetFile.');
}
