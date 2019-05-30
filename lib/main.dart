import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:calendar1/eventsPage.dart';


void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
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