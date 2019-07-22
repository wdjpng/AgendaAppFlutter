import 'package:flutter/material.dart';
import 'settingsPage.dart';
import 'eventsPage.dart';
import 'WebView.dart';
import 'Data.dart';

/// The [Drawer] used in the [EventsPageState]
class DrawerOnly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Drawer(
        child: new ListView(
      children: <Widget>[
        new DrawerHeader(
          child: new Container(
              child: Column(children: <Widget>[
            Material(
              borderRadius: BorderRadius.all(Radius.circular(80.0)),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(0.0),
                child: Image.asset('assets/images/icon.png',
                    width: 90, height: 90),
              ),
            ),
            Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'AgendaApp',
                  style: TextStyle(color: Colors.white, fontSize: 22.0),
                ))
          ])),
          decoration: new BoxDecoration(
              gradient: LinearGradient(
                  colors: <Color>[Colors.lightBlueAccent, Colors.blueAccent])),
        ),
        new ListTile(
            title: new Text("Kalender"),
            leading: new Icon(Icons.calendar_today),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EventsPage(title: 'AgendaApp')));
            }),
        ExpansionTile(
          leading: new Icon(Icons.info),
          title: Text("Informationen"),
          children: <Widget>[
            new ListTile(
                title: new Text("Stundenpläne"),
                leading: new Icon(Icons.web),
                onTap: () {
                  Data data = new Data();
                  data.url =
                      'https://www.sek-baeumlihof.ch/Planung%20des%20Schuljahres/copy_of_stundenplaene';
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WebViewPage(data: data)));
                }),
          ],
        ),
        Divider(
          height: 20.0,
        ),
        new ListTile(
            title: new Text("Einstellungen"),
            leading: new Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
            }),
      ],
    ));
  }
}
