import 'package:flutter/material.dart';
import 'selectorPage.dart';
import 'loginPage.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  void _openSelector(BuildContext context)/**/ {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SelectorPage()));
  }

  void _onSignIn(){
    Navigator.pop(context);
  }

  void _handleSignIn(){
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage(onSignedIn: _onSignIn,)));
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
