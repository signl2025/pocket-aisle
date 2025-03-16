import 'package:flutter/material.dart';
import 'package:get/get.dart';

//custom app bar, not much really, just the app bar with the "Home" and "Dictionary" and whatnot
class CustomAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton; //deprecated
  final VoidCallback? onMenuPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.indigo,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      leading:
          showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Get.back(),
              )
              : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuPressed,
              ),
    );
  }
}
