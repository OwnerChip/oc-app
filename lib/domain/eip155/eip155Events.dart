import 'package:ownerchip_whitelabel/domain/eip155.dart';
import 'package:ownerchip_whitelabel/domain/eip155/eip155.dart';

enum EIP155Events {
  chainChanged,
  accountsChanged,
}

extension EIP155EventsX on EIP155Events {
  String? get value => EIP155.events[this];
}

extension EIP155EventsStringX on String {
  EIP155Events? toEip155Event() {
    final entries = EIP155.events.entries.where(
          (element) => element.value == this,
    );
    return (entries.isNotEmpty) ? entries.first.key : null;
  }
}