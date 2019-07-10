import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'database_helpers.dart';

/// This widget is used to select the subjects whose events the user wants to
/// see in the [EventPage].
class SelectorPage extends StatefulWidget {
  @override
  _SelectorPageState createState() => new _SelectorPageState();
}

class _SelectorPageState extends State<SelectorPage> {
  /// The search result for the current search query as a list of subject names
  List<String> _searchResult = [];

  /// All the subjects the user can select. The String is the name of the subject
  /// and the whether it is selected is saved in the bool
  Map<String, bool> subjects = {};

  TextEditingController controller = new TextEditingController();

  @override
  void initState() {
    super.initState();
  }

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
            appBar: new AppBar(
              title: new Text('Home'),
              elevation: 0.0,
            ),
            body: new Column(
              children: <Widget>[
                /// The container for the search bar
                new Container(
                  color: Theme.of(context).primaryColor,
                  child: new Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: new Card(
                      child: new ListTile(
                        leading: new Icon(Icons.search),
                        title: new TextField(
                          controller: controller,
                          decoration: new InputDecoration(
                              hintText: 'Search', border: InputBorder.none),
                          onChanged: onSearchTextChanged,
                        ),
                        trailing: new IconButton(
                          icon: new Icon(Icons.cancel),
                          onPressed: () {
                            controller.clear();
                            onSearchTextChanged('');
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                /// The expander for the ListView
                new Expanded(
                    child: new ListView.builder(
                  itemCount: _searchResult.length,
                  itemBuilder: (context, i) {
                    return new CheckboxListTile(
                      title: new Text(_searchResult[i]),
                      value: subjects[_searchResult[i]],
                      onChanged: (bool value) {
                        setState(() {
                          subjects[_searchResult[i]] = value;
                        });
                        DatabaseHelper helper = DatabaseHelper.instance;
                        helper.updateSubjectSelection(_searchResult[i], value);
                      },
                    );
                  },
                )),
              ],
            ),
          );
        });
  }

  /// Updates the [_searchResult] according to the current search query
  onSearchTextChanged(String searchText) async {
    _searchResult.clear();
    if (searchText.isEmpty) {
      setState(() {});
      return;
    }

    for (var i = 0; i < subjects.keys.length; i++) {
      if (subjects.keys.elementAt(i).toString().contains(searchText)) {
        _searchResult.add(subjects.keys.elementAt(i).toString());
      }
    }

    _searchResult.sort();
    setState(() {});
  }
}
