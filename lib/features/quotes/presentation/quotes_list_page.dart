import 'package:flutter/material.dart';

import '../../../app/app_local_state.dart';
import '../../../shared/widgets/app_page_header.dart';

class QuotesListPage extends StatelessWidget {
  const QuotesListPage({super.key, required this.state});

  final AppLocalState state;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Proformas',
          subtitle: 'Listado visual vacío.',
        ),
      ],
    );
  }
}
