import 'package:flutter/material.dart';
import 'CustomRoundedButton.dart';
import '../utils/localization.helper.dart';

class TraitForm extends StatefulWidget {
  @override
  _TraitFormState createState() => _TraitFormState();
}

class _TraitFormState extends State<TraitForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keyTextController;
  late TextEditingController _valueTextController;
  List<Widget> traitsTextFields = [];
  static Map<String, String> traitsMap = {};
  static List<String> keyList = [];
  static List<String> valueList = [];
  // TODO: map keys to values

  @override
  void initState() {
    super.initState();
    _keyTextController = TextEditingController();
    _valueTextController = TextEditingController();
  }

  @override
  void dispose() {
    _keyTextController.dispose();
    _valueTextController.dispose();
    super.dispose();
  }

  /// get trait text-fields
  List<Widget> _getTraits() {
    for (int i = 0; i < keyList.length; i++) {
      traitsTextFields.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Expanded(child: TraitTextFields(i)),
            const SizedBox(width: 16),
            _addRemoveButton(i == keyList.length - 1, i),
          ],
        ),
      ));
    }
    return traitsTextFields;
  }

  /// add / remove button
  Widget _addRemoveButton(bool add, int index) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
      child: Text('+', style: TextStyle(fontSize: 20.0)),
      shape: RoundedRectangleBorder(
          side: BorderSide(
              color: Colors.black26, width: 1.0, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10.0)),
      onPressed: () {
        setState(() {
          traitsTextFields.add(TraitTextFields(index));
        });
      },
    ));
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
              Row(children: [
                Expanded(flex: 1, child: Container()),
                Expanded(flex: 18, child: TraitTextFields(1)),
                Expanded(flex: 1, child: Container()),
              ]),
              const SizedBox(
                height: 20,
              ),
              // ..._getTraits(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 50),
                  FloatingActionButton.extended(
                    onPressed: () => _getTraits(),
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
                  onChanged: (v) => _TraitFormState.keyList[widget.index] = v,
                  decoration: InputDecoration(hintText: context.loc.addValue),
                  validator: (v) {
                    if (v!.trim().isEmpty) return context.loc.pleaseEnterText;
                    return null;
                  },
                )
              ])),
          Expanded(flex: 2, child: Container())
        ]));
  }
}
