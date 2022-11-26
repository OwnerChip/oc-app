import 'package:flutter/material.dart';

class ScreenBodyLayout extends StatelessWidget {
  const ScreenBodyLayout({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 15),
            child: Row(
              children: [
                Expanded(flex: 1, child: Container()),
                Expanded(
                  flex: 18,
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: children,
                    ),
                  ),
                ),
                Expanded(flex: 1, child: Container()),
              ],
            )),
      ),
    );
  }
}
