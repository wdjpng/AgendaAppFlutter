import 'package:calendar1/models/Data.dart';
import 'package:calendar1/pages/loginPage.dart';
import 'package:calendar1/pages/selectorPage.dart';
import 'package:flutter/material.dart';
import 'package:calendar1/otherWidgets/alertShower.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Data data = new Data();

  @override
  void initState() {
    super.initState();
  }

  void _openSelector(BuildContext context) /**/ {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SelectorPage()));
  }

  void pop(){
    Navigator.pop(context);
    Navigator.pop(context);
  }
  void _onSignIn() {
    Navigator.pop(context);
    AlertShower.showAlert(context, 'ERFOLGREICHE ANMELDUNG',
        'Sie wurden soeben als Administrator angemeldet. Nun sind Sie in der Lage,'
            ' Nachrichten an ganze Klassen zu senden.',
        AlertType.success);
  }

  void _handleSignIn() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginPage(onSignedIn: _onSignIn, data: data)));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('AgendaApp'),
        elevation: 0.0,
      ),
      body: new ListView(
        children: <Widget>[
          new RaisedButton(
            onPressed: () => _openSelector(context),
            child: const Text(
              'Fächer auswählen',
            ),
          ),
          new RaisedButton(
            onPressed: () => _handleSignIn(),
            child: const Text(
              'Als Administrator anmelden',
            ),
          )
        ],
      ),
    );
  }
}
