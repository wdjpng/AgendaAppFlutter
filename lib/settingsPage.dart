import 'package:flutter/material.dart';
import 'selectorPage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  @override
  void initState() {
    super.initState();
  }

  void _openSelector(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SelectorPage()));
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
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
              'Fàcher auswählen',
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
