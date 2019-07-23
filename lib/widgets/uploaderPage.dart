import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:calendar1/models/Data.dart';
import 'package:calendar1/services/sqliteDatabaseHelpers.dart';
import 'package:calendar1/models/Event.dart';

/// This widget is used to add new sqlite events. It is opened when the
/// user clicks the floating button in the [EventPage].
class UploaderPage extends StatefulWidget {
  final Data data;
  final String title = "AgendaApp";

  UploaderPage({Key key, title, this.data}) : super(key: key);

  @override
  UploaderPageState createState() => UploaderPageState(data);
}

class UploaderPageState extends State<UploaderPage> {
  Data data;

  UploaderPageState(Data data) {
    this.data = data;
  }

  /// The [TextEditingController] of the input field for the message.
  TextEditingController messageText = new TextEditingController();

  DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = data.dateOfEvent;
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

  /// Returns the text for the button to select the date based on the selected date
  String getButtonText() {
    return 'Der ' +
        selectedDate.day.toString() +
        '. ' +
        selectedDate.month.toString() +
        '. ' +
        selectedDate.year.toString() +
        ' ist ausgewählt';
  }

  /// Shows a rflutter alert.
  void showMessage(
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

  /// Checks whether all input fields are filled in correctly.
  bool isCorrectUserData(String message, BuildContext context) {
    if (message == "") {
      showMessage(context, "NICHT ALLE FELDER AUSGEFÜLLT",
          "Bitte geben Sie eine Nachricht ein", AlertType.error);
      return false;
    }

    return true;
  }

  void popWidget() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  /// Adds new event to the offline sqlite database.
  pushEvent(String message) async {
    Event event = new Event(message, selectedDate);
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    int id = await helper.insertEvent(event);
    print('inserted row: $id');
  }

  /// Checks for correct user data, pushes new event to sqlite database and
  /// shows a success message.
  void onUploadButtonPressed(
      BuildContext context, TextEditingController textEditingController) {
    String message = textEditingController.text;

    ///Closes the keyboard
    FocusScope.of(context).requestFocus(new FocusNode());

    if (!isCorrectUserData(message, context)) {
      return;
    }

    pushEvent(message);
    showMessage(
        context, "DATEN ERFOLGREICH HOCHGELADEN", "", AlertType.success);
    FocusScope.of(context).requestFocus(new FocusNode());
    popWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            FloatingActionButton(
              onPressed: () => onUploadButtonPressed(context, messageText),
              tooltip: 'Bestätigen',
              child: Icon(Icons.done),
            ),
          ],
        ),
      ),
    );
  }
}
