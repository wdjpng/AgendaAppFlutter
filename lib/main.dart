import 'package:calendar1/pages/eventsPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

void main() {
  initializeDateFormatting().then((_) => runApp(AgendaApp()));
}

class AgendaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'AgendaApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EventsPage(title: 'AgendaApp'),
    );
  }
}
