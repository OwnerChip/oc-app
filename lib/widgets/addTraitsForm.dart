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
    List<Widget> TraitsTextFields = [];
    for (int i = 0; i < keyList.length; i++) {
      TraitsTextFields.add(Padding(
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
    return TraitsTextFields;
  }

  /// add / remove button
  Widget _addRemoveButton(bool add, int index) {
    return InkWell(
      onTap: () {
        if (add) {
          keyList.insert(0, "");
        } else
          keyList.removeAt(index);
        setState(() {});
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: (add) ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          (add) ? Icons.add : Icons.remove,
          color: Colors.white,
        ),
      ),
    );
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
                Expanded(
                    flex: 18,
                    child: Column(children: [
                      TextFormField(
                        controller: _keyTextController,
                        decoration: InputDecoration(hintText: 'key'),
                        onChanged: (k) {
                          keyList.add(k);
                        },
                        validator: (v) {
                          if (v!.trim().isEmpty)
                            return 'Please enter something';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _valueTextController,
                        decoration: InputDecoration(hintText: 'value'),
                        onChanged: (v) {
                          valueList.add(v);
                        },
                        // no validator neccessary
                      )
                    ])),
                Expanded(flex: 1, child: Container()),
              ]),
              SizedBox(
                height: 20,
              ),
              ..._getTraits(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 50),
                  FloatingActionButton.extended(
                    onPressed: () => _getTraits(),
                    label: const Text('Add Trait'),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              SizedBox(
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
      _keyController.text = _TraitFormState.keyList[widget.index];
      _valueController.text = _TraitFormState.valueList[widget.index];
    });

    return Row(children: [
      TextFormField(
        controller: _keyController,
        onChanged: (v) => _TraitFormState.keyList[widget.index] = v,
        decoration: InputDecoration(hintText: 'Enter a key'),
        validator: (v) {
          if (v!.trim().isEmpty) return 'Please enter something';
          return null;
        },
      ),
      TextFormField(
        controller: _valueController,
        onChanged: (v) => _TraitFormState.keyList[widget.index] = v,
        decoration: InputDecoration(hintText: 'Enter a value'),
        validator: (v) {
          if (v!.trim().isEmpty) return 'Please enter something';
          return null;
        },
      )
    ]);
  }
}
