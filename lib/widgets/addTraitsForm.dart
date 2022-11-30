import 'package:flutter/material.dart';
import 'dart:collection';
import 'CustomRoundedButton.dart';
import '../utils/localization.helper.dart';

class TraitForm extends StatefulWidget {
  @override
  _TraitFormState createState() => _TraitFormState();
}

class _TraitFormState extends State<TraitForm> {
  final _formKey = GlobalKey<FormState>();
  int count = 0;
  List<Widget> traitsTextFields = [];
  static List<String> keyList = [""];
  static List<String> valueList = [""];
  Map<String, String> traitsMap = {};

  void mapLists() {
    for (int i = 0; i < keyList.length; i++) {
      traitsMap[keyList[i]] = valueList[i];
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    count = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // show KEY-VALUE forms
              for (int i = 0; i < count; i++) traitsTextFields[i],
              if (count < 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: 50),
                    FloatingActionButton.extended(
                      onPressed: () => {
                        setState(() {
                          traitsTextFields.add(TraitTextFields(1));
                          count++;
                        }),
                      },
                      label: Text(context.loc.addTrait),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              const SizedBox(
                height: 40,
              ),
              CustomRoundedButton(
                  text: context.loc.save,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      mapLists();
                      print(traitsMap);
                      Navigator.pop(context, traitsMap);
                    }
                  }),
            ],
          ),
        ));
  }
}

class TraitTextFields extends StatefulWidget {
  final int index;
  TraitTextFields(this.index);
  @override
  _TraitTextFieldsState createState() => _TraitTextFieldsState();
}

class _TraitTextFieldsState extends State<TraitTextFields> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _keyController.text = _TraitFormState.keyList[widget.index] ?? "";
      _valueController.text = _TraitFormState.valueList[widget.index] ?? "";
    });

    return Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColor, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(13)),
            boxShadow: [
              const BoxShadow(
                  blurRadius: 13,
                  color: const Color.fromARGB(255, 249, 247, 247),
                  offset: Offset(1, 3))
            ]),
        child: Row(children: [
          Expanded(flex: 2, child: Container()),
          Expanded(
              flex: 16,
              child: Column(children: [
                TextFormField(
                  controller: _keyController,
                  onChanged: (v) => _TraitFormState.keyList[widget.index] = v,
                  decoration: InputDecoration(hintText: context.loc.addKey),
                  validator: (v) {
                    if (v!.trim().isEmpty) return context.loc.pleaseEnterText;
                    return null;
                  },
                ),
                const SizedBox(width: 15),
                TextFormField(
                  controller: _valueController,
                  onChanged: (v) => _TraitFormState.valueList[widget.index] = v,
                  decoration: InputDecoration(hintText: context.loc.addValue),
                  validator: (v) {
                    if (v!.trim().isEmpty) return context.loc.pleaseEnterText;
                    return null;
                  },
                ),
              ])),
          Expanded(flex: 2, child: Container())
        ]));
  }
}
