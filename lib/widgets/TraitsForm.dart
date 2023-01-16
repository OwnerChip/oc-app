import 'package:flutter/material.dart';
import 'package:owner_chip_admin_demo/widgets/CustomRoundedButton.dart';
import '../themes/fontSpecs.dart';
import '../themes/colorSpecs.dart';
import '../utils/localization.helper.dart';

class TraitsForm extends StatefulWidget {
  TraitsForm(
      {required this.submitFunction,
      required this.toggleTraitsForm,
      required this.initialTraitsArray});

  Function submitFunction;
  Function toggleTraitsForm;
  List initialTraitsArray;

  @override
  _TraitsForm createState() => _TraitsForm();
}

class _TraitsForm extends State<TraitsForm> {
  final _formKey = GlobalKey<FormState>();
  List<Widget> traitsTextFields = [];
  static List<Map> traitsArray = [];

  //initialize TextFields with already defined traits
  void initState() {
    super.initState();
    widget.initialTraitsArray.forEach((val) {
      traitsTextFields.add(TraitTextInput(
          index: traitsTextFields.length,
          initialText: [val["trait_type"], val["value"]]));
    });
    if (traitsTextFields.length == 0) {
      traitsArray.add({"trait_type": "", "value": ""});
      traitsTextFields.add(TraitTextInput(index: traitsTextFields.length));
    }
  }

  void addTraitInput() {
    setState(() {
      traitsArray.add({"trait_type": "", "value": ""});
      traitsTextFields.add(TraitTextInput(index: traitsTextFields.length));
    });
  }

  void removeTraitInput() {
    if (traitsTextFields.length > 0) {
      traitsArray.removeLast();
      setState(() {
        traitsTextFields.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomRoundedButton(
                  height: 25,
                  width: 100,
                  backgroundColor: Colors.grey,
                  text: context.loc.remove,
                  textStyle: Theme.of(context).textTheme.bodyText1!.copyWith(
                      color: CustomColors.customRoundedButtonColor,
                      fontSize: CustomFonts.bodyText2FontSize / 1.3),
                  onPressed: () => removeTraitInput()),
              SizedBox(width: 10),
              CustomRoundedButton(
                  height: 25,
                  width: 100,
                  text: context.loc.add,
                  textStyle: Theme.of(context).textTheme.bodyText1!.copyWith(
                      color: CustomColors.customRoundedButtonColor,
                      fontSize: CustomFonts.bodyText2FontSize / 1.3),
                  onPressed: () => addTraitInput()),
            ],
          ),
          ...traitsTextFields,
          SizedBox(height: 20),
          CustomRoundedButton(
              text: context.loc.save,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  //check if key or value of map in traitsArray is empty string
                  for (int i = 0; i < traitsArray.length; i++) {
                    if (traitsArray[i]["trait_type"] == "" ||
                        traitsArray[i]["value"] == "") {
                      traitsArray.removeAt(i);
                    }
                  }
                  widget.submitFunction(traitsArray);
                }
              }),
          SizedBox(height: 10),
          CustomRoundedButton(
              text: context.loc.cancel,
              backgroundColor: Colors.grey,
              onPressed: () =>
                  {traitsArray.removeLast(), widget.toggleTraitsForm()})
        ]));
  }
}

class TraitTextInput extends StatefulWidget {
  TraitTextInput({required this.index, this.initialText});

  final int index;
  final List<String>? initialText;

  @override
  _TraitTextInput createState() => _TraitTextInput();
}

class _TraitTextInput extends State<TraitTextInput> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialText?[0] ?? "");
    _valueController =
        TextEditingController(text: widget.initialText?[1] ?? "");
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: _keyController,
            decoration: InputDecoration(
              labelText: context.loc.type,
              // hintText: 'Enter name of trait',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.loc.pleaseEnterText;
              }
              return null;
            },
            onSaved: (value) {
              _TraitsForm.traitsArray[widget.index]["trait_type"] =
                  _keyController.text;
            },
          ),
        ),
        SizedBox(width: 10),
        Expanded(
            flex: 4,
            child: TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: context.loc.value,
                // hintText: 'Enter trait value',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.loc.pleaseEnterText;
                }
                return null;
              },
              onSaved: (value) {
                _TraitsForm.traitsArray[widget.index]["value"] =
                    _valueController.text;
              },
            ))
      ],
    );
  }
}
