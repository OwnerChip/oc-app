import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import '../widgets/AppBarWithLogo.dart';
import 'LoginScreen.dart';

//stateful widget with name MetadataScreen
class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key, this.connector});

  final WalletConnect? connector;

  static const routeName = '/metadata-input';

  @override
  State<MetadataScreen> createState() => _MetadataScreen();
}

class _MetadataScreen extends State<MetadataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBarWithLogo(
          loginFunction: () => {},
          text: 'Initialize Chip',
          connectedWallet: widget.connector!.session?.accounts!.isEmpty == true
              ? null
              : widget.connector!.session?.accounts![0].toLowerCase(),
        ),
        body: SafeArea(
            child: Center(
                child: Padding(
                    padding: EdgeInsets.all(25.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Please enter your metadata'),
                          Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      hintText: 'Title',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter some text';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  TextField(
                                    maxLines: 2,
                                    keyboardType: TextInputType.multiline,
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      hintText: 'Description',
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content:
                                                      Text('Processing Data')));
                                        }
                                      },
                                      child: const Text('Submit'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 200,
                                    height: 50,
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.grey, // background
                                        ),
                                        onPressed: () => {
                                              Navigator.pushNamed(context,
                                                  LoginScreen.routeName)
                                            },
                                        child: const Text('Cancel')),
                                  )
                                ],
                              ))
                        ])))));
  }
}
