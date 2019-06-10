import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helpers.dart';
import 'database_helpers.dart';
class SelectorPage extends StatefulWidget {
  @override
  SelectorState createState() => new SelectorState();
}

class SelectorState extends State<SelectorPage> {
  Map<String, bool> values = {
  };

  void updateSubjects(List<DocumentSnapshot> snapshot){
    for(var i = 0; i < snapshot.length; i++){
      DatabaseHelper helper = DatabaseHelper.instance;
      helper.insertSubjectIfAbsent(snapshot[i]['name']);
    }
  }

  _readEvents() async{
    DatabaseHelper helper = DatabaseHelper.instance;
    List<Map> maps = await helper.getSavedSubjects() ?? List<Map>();

    if(maps.length>0){
      values = Map<String, bool>();
      for(var i = 0; i < maps.length; i++){
        bool isTrue = maps[i][columnIsSelected] == 1;
        values.putIfAbsent(maps[i][columnName], () => isTrue);
      }
    }
   setState(() {

   });
  }

    @override
  Widget build(BuildContext context){
    return StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          updateSubjects(snapshot.data.documents);
           _readEvents();
          return new Scaffold(
            appBar: new AppBar(title: new Text('AgendaApp')),
            body: new ListView(
              children: values.keys.map((String key) {
                return new CheckboxListTile(
                  title: new Text(key),
                  value: values[key],
                  onChanged: (bool value) {
                    setState(() {
                      values[key] = value;
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
