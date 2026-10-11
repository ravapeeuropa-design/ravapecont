import 'package:flutter/material.dart';

class AppDataTable extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: const Color(0xFF2A2A2A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DataTable(
        columns: columns,
        rows: rows,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFF181818)),
        dataRowColor: const WidgetStatePropertyAll(Color(0xFF111111)),
        dividerThickness: 0.5,
        headingTextStyle: const TextStyle(color: Colors.white),
        dataTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
