import 'package:calendar1/widgets/eventsPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(AgendaApp()));
}

class AgendaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventsPage(title: 'AgendaApp'),
    );
  }
}
