import 'package:flutter/material.dart';

class CompanyDocumentsPage extends StatelessWidget {
  const CompanyDocumentsPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title));
  }
}
