import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'store/store_desktop.dart';
import 'store/store_mobile.dart';

class StorePage extends StatelessWidget {
  const StorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: StoreMobile(),
      desktop: StoreDesktop(),
    );
  }
}
