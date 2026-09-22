import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'scanned_products_screen.dart';

class CompliantProductsScreen extends StatelessWidget {
  const CompliantProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScannedProductsScreen(initialFilter: ComplianceStatus.compliant);
  }
}
