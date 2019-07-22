import 'package:flutter/material.dart';
import 'selectorPage.dart'
;
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  void initState() {
    super.initState();
  }

  void _openSelector(BuildContext){
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => SelectorPage()));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('AgendaApp'),
        elevation: 0.0,
      ),
      body: new ListView(
        children: <Widget>[new RaisedButton(onPressed: () => _openSelector(context), child: const Text(
            'Fàcher auswählen',
        ),)],
      ),
    );
  }
}
