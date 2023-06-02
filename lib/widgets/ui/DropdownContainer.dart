import 'package:flutter/material.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomCard.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class DropdownContainer extends StatefulWidget {
  DropdownContainer(
      {super.key,
      this.isInitiallyExpanded = false,
      required this.title,
      required this.content});

  bool isInitiallyExpanded;
  final Widget? content;
  final String title;

  @override
  State<DropdownContainer> createState() => _DropdownContainerState();
}

class _DropdownContainerState extends State<DropdownContainer>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.content != null ? widget.isInitiallyExpanded : false;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    if (isExpanded) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //toggle isExpanded
  void toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
        margin: EdgeInsets.only(
          top: 5.0,
          bottom: 5.0,
        ),
        padding: const EdgeInsets.only(
            top: 5.0, bottom: 10.0, left: 10.0, right: 10.0),
        color: CustomColors(dotenv.get('APP_ID')).cardColor,
        children: [
          GestureDetector(
              onTap: () => toggleExpanded(),
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.left),
                    IconButton(
                      icon: RotationTransition(
                          turns:
                              Tween(begin: 0.0, end: 0.5).animate(_controller),
                          child: widget.content == null
                              ? const Icon(Icons.expand_less_rounded)
                              : const Icon(Icons.expand_more_rounded)),
                      color: CustomColors(dotenv.get('APP_ID')).black,
                      onPressed: widget.content == null
                          ? null
                          : () {
                              toggleExpanded();
                            },
                    )
                  ],
                ),
              )),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            // vsync: this,
            child: isExpanded
                ? AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        Divider(
                          color: Theme.of(context).primaryColor,
                          height: 20,
                          thickness: 1,
                          indent: 0,
                          endIndent: 0,
                        ),
                        Align(
                            //alignment left
                            alignment: Alignment.centerLeft,
                            child: widget.content ?? Container())
                      ],
                    ))
                : Container(),
          ),
        ]);
  }
}
