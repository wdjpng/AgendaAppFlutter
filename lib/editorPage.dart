import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'Data.dart';
import 'database_helpers.dart';
import 'Event.dart';

class EditorPage extends StatefulWidget {
  final Data data;
  final String title = "AgendaApp";

  EditorPage({Key key, title, this.data}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState(data);
}

class _EditorPageState extends State<EditorPage> {
  Data data;
  final key = new GlobalKey<ScaffoldState>();

  _EditorPageState(Data data) {
    this.data = data;
  }

  TextEditingController messageText = new TextEditingController();

  DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = data.dateTime;
    messageText.text = data.message;
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2019, 4),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
    print('Date selected: ' + selectedDate.toIso8601String());
  }

  String getButtonText() {
    return 'Der ' +
        selectedDate.day.toString() +
        '. ' +
        selectedDate.month.toString() +
        '. ' +
        selectedDate.year.toString() +
        ' ist ausgewählt';
  }

  void showAlert(
      BuildContext context, String title, String message, AlertType alertType) {
    Alert(
      context: context,
      type: alertType,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          width: 120,
        )
      ],
    ).show();
  }

  bool isCorrectUserData(String message, BuildContext context) {
    if (message == "") {
      showAlert(context, "NICHT ALLE FELDER AUSGEFÜLLT",
          "Bitte geben Sie eine Nachricht ein", AlertType.error);
      return false;
    }

    return true;
  }

  void popWidget() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void pushEvent(String message) async {
    Event event = new Event(message, selectedDate);
    DatabaseHelper helper = DatabaseHelper.instance;
    int id = await helper.insertEvent(event);
    print('inserted row: $id');
  }

  void updateEvent(Data oldData, String newMessage, DateTime newDateOfEvent){
    DatabaseHelper helper = DatabaseHelper.instance;
    helper.updateEvent(oldData.message, newMessage, newDateOfEvent);
  }

  void onUpdateButtonPressed(BuildContext context, Data data, String newMessage) {

    if (!isCorrectUserData(newMessage, context)) {
      return;
    }

    updateEvent(data, newMessage, selectedDate);

    showAlert(
        context, "Eintrag erfolgreich verändert", "", AlertType.success);
    FocusScope.of(context).requestFocus(new FocusNode());
    popWidget();
  }

  void onDeletionConfirmed(Data data, BuildContext context){
    deleteEvent(data);
    Navigator.pop(context);
    Navigator.pop(context);
  }
  void deleteEvent(Data data) async{
    DatabaseHelper helper = DatabaseHelper.instance;
    int id = await helper.deleteEvent(data.message);
    print('deleted row: $id');
  }

  void onDeleteButtonPressed(BuildContext context, Data data) {
    Alert(
      context: context,
      type: AlertType.warning,
      title: 'Wirklich löschen?',
      desc: 'Diese Nachricht wird unwiederbringlich gelöscht werden',
      buttons: [
        DialogButton(
          color: Colors.green,
          child: Text(
          "NEIN",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => Navigator.pop(context),
          width: 120,
        ),
        DialogButton(
          color : Colors.red,
          child: Text(
            "JA",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () => onDeletionConfirmed(data, context),
          width: 120,
        )
      ],
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key:key,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 20.0,
            ),
            RaisedButton(
              textColor: Colors.white,
              color: Colors.lightBlue,
              onPressed: () => _selectDate(context),
              child: Text(getButtonText()),
            ),
            new Container(
              width: 350.0,
              child: TextField(
                  controller: messageText,
                  keyboardType: TextInputType.multiline,
                  maxLines: 2,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(), labelText: 'Nachricht')),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => onDeleteButtonPressed(context, data),
                  tooltip: 'Löschen',
                  child: Icon(Icons.delete),
                  backgroundColor: Colors.red,
                  heroTag: 'floatingActionButton1',
                ),
                SizedBox(width: 35),
                FloatingActionButton(
                  onPressed: () => onUpdateButtonPressed(context, data, messageText.text),
                  tooltip: 'Bestätigen',
                  child: Icon(Icons.done),
                  heroTag: 'floatingActionButton0',
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
