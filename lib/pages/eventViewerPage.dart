import 'dart:async';

import 'package:calendar1/models/Data.dart';
import 'package:calendar1/models/Event.dart';
import 'package:calendar1/services/sqliteDatabaseHelpers.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:calendar1/otherWidgets/alertShower.dart';
import 'package:calendar1/services/fireStoreHelpers.dart';

/// This widget is used to edit existing sqlite events. It is opened when the
/// user clicks on a sqlite event in the [EventPage].
class EventViewerPage extends StatefulWidget {
  final Data data;
  final String title = "AgendaApp";

  EventViewerPage({Key key, title, this.data}) : super(key: key);

  @override
  EventViewerPageState createState() => EventViewerPageState(data);
}

class EventViewerPageState extends State<EventViewerPage> {
  Data data;
  String selectedSubject;

  /// This key is used to be able to show snackbars.
  final key = new GlobalKey<ScaffoldState>();

  EventViewerPageState(Data data) {
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

    if(data.isInAdminMode && data.isInEditMode){
      Event thisEvent = new Event(data.message, selectedDate);
      for(var i = 0; i < data.onlineEvents.length; i++){
        if(thisEvent.areDateAndMessageEqual(data.onlineEvents[i])){
          selectedSubject = data.onlineEvents[i].subject;
        }
      }
    }
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
    if (message == "" && selectedSubject == null && data.isInAdminMode) {
      AlertShower.showAlert(context, "NICHT ALLE FELDER AUSGEFÜLLT",
          "Bitte geben Sie eine Nachricht ein und wählen Sie eine Klasse aus", AlertType.error);
      return false;
    } else if(message == ""){
      AlertShower.showAlert(context, "NICHT ALLE FELDER AUSGEFÜLLT",
          "Bitte geben Sie eine Nachricht ein", AlertType.error);
      return false;
    } else if(selectedSubject == null && data.isInAdminMode){
      AlertShower.showAlert(context, "NICHT ALLE FELDER AUSGEFÜLLT",
          "Bitte wählen Sie eine Klasse aus", AlertType.error);
      return false;
    }

    return true;
  }

  void popContextTwice() {
    Navigator.pop(context);
    Navigator.pop(context);
  }

  /// Adds new event to the offline sqlite database.
  void pushEventOffline(String message) async {
    Event event = new Event(message, selectedDate);
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    int id = await helper.insertEvent(event);
    print('inserted row: $id');
  }

  /// Adds new event to the online firestore database.
  void pushEventOnline(String message) async {
    FirestoreHelper.pushEvent(message, selectedDate, selectedSubject);
  }

  /// Updates an event in the offline sqlite database.
  void updateEventOffline(Data oldData, String newMessage, DateTime newDateOfEvent) {
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

    if(data.isInAdminMode){
      Event oldEvent = new Event(data.message, data.dateOfEvent);
      Event newEvent = new Event(newMessage, selectedDate);
      newEvent.subject = selectedSubject;

      FirestoreHelper.updateEvent(oldEvent, newEvent, data.onlineEvents);
    } else{
      updateEventOffline(data, newMessage, selectedDate);
    }
    

    AlertShower.showAlert(
        context, "Eintrag erfolgreich verändert", "", AlertType.success);
    FocusScope.of(context).requestFocus(new FocusNode());
    popContextTwice();
  }

  /// Deletes an event and closes the alert as well as the input form.
  void onDeletionConfirmed(Data data, BuildContext context) {
    if(data.isInAdminMode){
      FirestoreHelper.deleteEvent(new Event(data.message, data.dateOfEvent), data.onlineEvents);
    } else {
      deleteEventOffline(data);
    }

    popContextTwice();
  }

  /// Deletes the event in the offline sqlite database.
  void deleteEventOffline(Data data) async {
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    int id = await helper.deleteEvent(data.message);
    print('deleted row: $id');
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

    if (data.isInAdminMode) {
      pushEventOnline(message);
    } else {
      pushEventOffline(message);
    }

    AlertShower.showAlert(
        context, "DATEN ERFOLGREICH HOCHGELADEN", "", AlertType.success);
    FocusScope.of(context).requestFocus(new FocusNode());

    popContextTwice();
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
            data.isInAdminMode
                ? new DropdownButton<String>(
                    value: selectedSubject,
                    hint: Text('Klasse auswählen'),
                    items: data.subjects
                        .map((label) => DropdownMenuItem(
                              child: Text(label),
                              value: label,
                            ))
                        .toList(),
                    onChanged: (String newValue) {
                      setState(() {
                        selectedSubject = newValue;
                      });
                    },
                    //TODO find better way then empty sized box
                  )
                : SizedBox(height: 1),
            SizedBox(height: 20),
            data.isInEditMode
                ? Row(
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
                        onPressed: () => eventUpdateHandler(
                            context, data, messageTextController.text),
                        tooltip: 'Bestätigen',
                        child: Icon(Icons.done),
                        heroTag: 'floatingActionButton0',
                      )
                    ],
                  )
                : FloatingActionButton(
                    onPressed: () =>
                        onUploadButtonPressed(context, messageTextController),
                    tooltip: 'Bestätigen',
                    child: Icon(Icons.done),
                  ),
          ],
        ),
      ),
    );
  }
}
