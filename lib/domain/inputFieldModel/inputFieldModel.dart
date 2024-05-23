import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';

class InputFieldModel {
  final String? placeholder;
  final TextInputType? keyboardType;
  final VoidStringCallback setStateCallback;
  final StringCallback validator;

  InputFieldModel({
    this.placeholder = '',
    this.keyboardType = TextInputType.text,
    required this.setStateCallback,
    required this.validator,
  });
}
