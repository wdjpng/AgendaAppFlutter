import 'dart:async';

import 'package:calendar1/models/Data.dart';
import 'package:calendar1/models/Event.dart';
import 'package:calendar1/services/sqliteDatabaseHelpers.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

/// This widget is used to edit existing sqlite events. It is opened when the
/// user clicks on a sqlite event in the [EventPage].
class EditorPage extends StatefulWidget {
  final Data data;
  final String title = "AgendaApp";

  EditorPage({Key key, title, this.data}) : super(key: key);

  @override
  EditorPageState createState() => EditorPageState(data);
}

class EditorPageState extends State<EditorPage> {
  Data data;

  /// This key is used to be able to show snackbars.
  final key = new GlobalKey<ScaffoldState>();

  EditorPageState(Data data) {
    this.data = data;
  }

  /// The [TextEditingController] of the input field for the message.
  TextEditingController messageTextController = new TextEditingController();
  DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = data.dateOfEvent;
    messageTextController.text = data.message;
  }

  /// Opens the date selector.
  Future<Null> _selectDate(BuildContext context) async {
    ///Closes the keyboard
    FocusScope.of(context).requestFocus(new FocusNode());

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

  /// Shows a rflutter alert.
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

  /// Returns the text for the button to select the date based on the selected date.
  String getButtonText(DateTime selectedDate) {
    return 'Der ' +
        selectedDate.day.toString() +
        '. ' +
        selectedDate.month.toString() +
        '. ' +
        selectedDate.year.toString() +
        ' ist ausgewählt';
  }

  /// Checks whether all input fields are filled in correctly.
  bool isCorrectUserData(String message, BuildContext context) {
    if (message == "") {
      showAlert(context, "NICHT ALLE FELDER AUSGEFÜLLT",
          "Bitte geben Sie eine Nachricht ein", AlertType.error);
      return false;
    }

    return true;
  }

  void popContextTwice() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  /// Adds new event to the offline sqlite database.
  void pushEvent(String message) async {
    Event event = new Event(message, selectedDate);
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    int id = await helper.insertEvent(event);
    print('inserted row: $id');
  }

  /// Updates an event in the offline sqlite database.
  void updateEvent(Data oldData, String newMessage, DateTime newDateOfEvent) {
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    helper.updateEvent(oldData.message, newMessage, newDateOfEvent);
  }

  /// Checks for correct user data, updates the data and shows a success message.
  void eventUpdateHandler(BuildContext context, Data data, String newMessage) {
    ///Closes the keyboard
    FocusScope.of(context).requestFocus(new FocusNode());

    if (!isCorrectUserData(newMessage, context)) {
      return;
    }

    updateEvent(data, newMessage, selectedDate);

    showAlert(context, "Eintrag erfolgreich verändert", "", AlertType.success);
    FocusScope.of(context).requestFocus(new FocusNode());
    popContextTwice();
  }

  /// Deletes an event and closes the alert as well as the input form.
  void onDeletionConfirmed(Data data, BuildContext context) {
    deleteEvent(data);
    popContextTwice();
  }

  /// Deletes the event in the offline sqlite database.
  void deleteEvent(Data data) async {
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    int id = await helper.deleteEvent(data.message);
    print('deleted row: $id');
  }

  /// Asks the user whether he really wants to delete the event and either closes
  /// the windows or calls the [onDeletionConfirmed] method.
  void onDeleteButtonPressed(BuildContext context, Data data) {
    ///Closes the keyboard
    FocusScope.of(context).requestFocus(new FocusNode());

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
          color: Colors.red,
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
      key: key,
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
              child: Text(getButtonText(selectedDate)),
            ),
            new Container(
              width: 350.0,
              child: TextField(
                  controller: messageTextController,
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
                  onPressed: () =>
                      eventUpdateHandler(
                          context, data, messageTextController.text),
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
