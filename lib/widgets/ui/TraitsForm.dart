import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomOutlinedButton.dart';

class TraitsForm extends StatefulWidget {
  TraitsForm({
    super.key,
    required this.submitFunction,
    required this.toggleTraitsForm,
    required this.traitsStateArray,
  });

  Function submitFunction;
  Function toggleTraitsForm;
  List traitsStateArray;

  @override
  TraitsFormState createState() => TraitsFormState();
}

class TraitsFormState extends State<TraitsForm> {
  final _formKey = GlobalKey<FormState>();
  List<Widget> traitsTextFields = [];

  //initialize TextFields with already defined traits
  @override
  void initState() {
    super.initState();
    for (var val in widget.traitsStateArray) {
      traitsTextFields.add(TraitTextInput(
          index: traitsTextFields.length,
          initialText: [val["trait_type"], val["value"]],
          traitsStateArray: widget.traitsStateArray,
          removeTraitInput: removeTraitInput));
    }
    if (traitsTextFields.isEmpty) {
      widget.traitsStateArray.add({"trait_type": "", "value": ""});
      traitsTextFields.add(TraitTextInput(
          index: traitsTextFields.length,
          traitsStateArray: widget.traitsStateArray,
          removeTraitInput: removeTraitInput));
    }
  }

  void addTraitInput() {
    //new focus node
    FocusNode focusNode = FocusNode();
    setState(() {
      widget.traitsStateArray.add({"trait_type": "", "value": ""});
      traitsTextFields.add(TraitTextInput(
          index: traitsTextFields.length,
          focusNode: focusNode,
          traitsStateArray: widget.traitsStateArray,
          removeTraitInput: removeTraitInput));
    });
    //focus focusNode
    focusNode.requestFocus();
  }

  void removeTraitInput(int index) {
    if (traitsTextFields.isNotEmpty) {
      setState(() {
        widget.traitsStateArray.removeAt(index);
        traitsTextFields.removeAt(index);
        // Regenerate widgets to make sure index is correct
        List<Widget> newTraitsTextFields = [];
        for (int i = 0; i < traitsTextFields.length; i++) {
          newTraitsTextFields.add(TraitTextInput(
            key: ValueKey(widget.traitsStateArray[i]
                ["trait_type"]), // Unique key for each widget
            index: i,
            initialText: [
              widget.traitsStateArray[i]["trait_type"],
              widget.traitsStateArray[i]["value"]
            ],
            traitsStateArray: widget.traitsStateArray,
            removeTraitInput: removeTraitInput,
          ));
        }
        traitsTextFields = newTraitsTextFields;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: CustomColors(dotenv.get('APP_ID')).cardColor,
        child: Form(
            key: _formKey,
            child: Column(children: <Widget>[
              ...traitsTextFields,
              const SizedBox(height: 20),
              CustomOutlinedButton(
                  buttonText: context.loc.add,
                  width: double.infinity,
                  onPressed: () {
                    addTraitInput();
                  }),
              const SizedBox(height: 10),
            ])));
  }
}

class TraitTextInput extends StatefulWidget {
  const TraitTextInput(
      {super.key,
      required this.index,
      this.focusNode,
      this.initialText,
      required this.traitsStateArray,
      required this.removeTraitInput});

  final int index;
  final List<String>? initialText;
  final FocusNode? focusNode;
  final List traitsStateArray;
  final Function removeTraitInput;

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.bold),
            autofocus: false,
            focusNode: widget.focusNode,
            controller: _keyController,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              hintText: context.loc.type,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.loc.pleaseEnterText;
              }
              return null;
            },
            onChanged: (value) {
              widget.traitsStateArray[widget.index]["trait_type"] =
                  _keyController.text;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
            flex: 4,
            child: TextFormField(
              style: Theme.of(context).textTheme.bodyMedium,
              controller: _valueController,
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                hintStyle: Theme.of(context).textTheme.bodySmall,
                hintText: context.loc.enterDetails,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.loc.pleaseEnterText;
                }
                return null;
              },
              onChanged: (value) {
                widget.traitsStateArray[widget.index]["value"] =
                    _valueController.text;
              },
            )),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.removeTraitInput(widget.index);
            },
          ),
        ),
      ],
    );
  }
}
