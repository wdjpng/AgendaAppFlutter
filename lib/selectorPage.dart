import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helpers.dart';

/// This widget is used to select the subjects whose events the user wants to
/// see in the [EventPage].
class SelectorPage extends StatefulWidget {
  @override
  SelectorState createState() => new SelectorState();
}

class SelectorState extends State<SelectorPage> {
  /// All the subjects the user can select. The String is the name of the subject
  /// and the whether it is selected is saved in the bool
  Map<String, bool> subjects = {};

  /// Updates the offline sqlite subjects with the online firestore subjects.
  void updateSubjects(List<DocumentSnapshot> snapshot) {
    for (var i = 0; i < snapshot.length; i++) {
      DatabaseHelper helper = DatabaseHelper.instance;
      helper.insertSubjectIfAbsent(snapshot[i]['name']);
    }
  }

  /// Reads the subjects from the offline sqlite database and stores them in the
  /// [subjects] map.
  void _readSubjects() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    List<Map> maps = await helper.getSavedSubjects() ?? List<Map>();

    if (maps.length > 0) {
      subjects = Map<String, bool>();
      for (var i = 0; i < maps.length; i++) {
        bool isTrue = maps[i][columnIsSelected] == 1;
        subjects.putIfAbsent(maps[i][columnName], () => isTrue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          updateSubjects(snapshot.data.documents);
          _readSubjects();
          return new Scaffold(
            appBar: new AppBar(title: new Text('AgendaApp')),
            body: new ListView(
              children: subjects.keys.map((String key) {
                return new CheckboxListTile(
                  title: new Text(key),
                  value: subjects[key],
                  onChanged: (bool value) {
                    setState(() {
                      subjects[key] = value;
                    });
                    DatabaseHelper helper = DatabaseHelper.instance;
                    helper.updateSubjectSelection(key, value);
                  },
                );
              }).toList(),
            ),
          );
        });
  }
}
