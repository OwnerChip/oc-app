import 'package:flutter/material.dart';

//Card widget that can take multiple children
class CustomCard extends StatelessWidget {
  const CustomCard({super.key, required this.heading, required this.body});

  final List<Widget> heading;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border:
              Border.all(color: Color.fromARGB(255, 249, 247, 247), width: 1),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).shadowColor,
                blurRadius: 5,
                offset: const Offset(3, 4)),
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...heading,
          //spacing
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).primaryColor,
            height: 20,
            thickness: 1,
            indent: 0,
            endIndent: 0,
          ),
          const SizedBox(height: 10),

          ...body
        ],
      ),
    );
  }
}
