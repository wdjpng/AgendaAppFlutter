import 'package:calendar1/models/Data.dart';
import 'package:calendar1/models/Event.dart';
import 'package:calendar1/otherWidgets/drawer.dart';
import 'package:calendar1/pages/eventViewerPage.dart';
import 'package:calendar1/services/fireStoreHelpers.dart';
import 'package:calendar1/services/sqliteDatabaseHelpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar1/services/authentication.dart';
import 'package:calendar1/models/Subject.dart';
import 'package:calendar1/models/Converter.dart';

DateTime currentDateTime = DateTime.now();

/// The main widget shows the events of the selected subjects and directs the
/// user to other widgets.
class EventsPage extends StatefulWidget {
  EventsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  EventsPageState createState() => EventsPageState();
}

class EventsPageState extends State<EventsPage> with TickerProviderStateMixin {
  DateTime _selectedDay;
  Map<DateTime, List> eventsAsStrings;
  List<Event> onlineEvents;
  Map<DateTime, List> visibleEvents;
  List<Event> sqliteEvents = List<Event>();
  List<String> chosenSubjects = List<String>();
  List _selectedEvents;
  final key = new GlobalKey<ScaffoldState>();
  static bool isInAdminMode;

  AnimationController _controller;

  void initState() {
    super.initState();
    _selectedDay = currentDateTime;

    eventsAsStrings = {
      _selectedDay: ['Heute']
    };

    _selectedEvents = eventsAsStrings[_selectedDay] ?? [];
    visibleEvents = eventsAsStrings;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _controller.forward();

    updateAdminMode();
  }

  void updateAdminMode() async{
    Auth auth = new Auth();
    isInAdminMode = await auth.isUserSignedIn();
  }
  void _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedDay = day;
      _selectedEvents = events;
    });

    print('Selected day: $day');
  }

  void _onVisibleDaysChanged(
      DateTime first, DateTime last, CalendarFormat format) {
    setState(() {
      visibleEvents = Map.fromEntries(
        eventsAsStrings.entries.where(
          (entry) =>
              entry.key.isAfter(first.subtract(const Duration(days: 1))) &&
              entry.key.isBefore(last.add(const Duration(days: 1))),
        ),
      );
    });

    print('First visible day: $first');
    print('Last visible day: $last');
    print('Current format: $format');
  }

  /// Opens the [UploaderPage]
  void onWriteOwnMessageButtonPressed(BuildContext context) {
    Data data = new Data();
    data.dateOfEvent = _selectedDay;
    data.isInEditMode = false;
    data.isInAdminMode = isInAdminMode;
    data.subjects = chosenSubjects;
    data.onlineEvents = onlineEvents;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              EventViewerPage(
                data: data,
              )),
    );
  }

  /// Checks whether the message is in the offline sqlite database
  bool isOfflineEvent(String message, DateTime dateOfEvent) {
    for (var i = 0; i < sqliteEvents.length; i++) {
      if (sqliteEvents[i].message == message && sqliteEvents[i].dateOfEvent == dateOfEvent) {
        return true;
      }
    }

    return false;
  }

  /// Called when the user clicks on an event, checks wether the user can edit
  /// it and if so opens the [EventViewerPage] to edit that message.
  void onEventPressed(BuildContext context, String message) {
    if ((isOfflineEvent(message, _selectedDay) || isInAdminMode) && message != 'Heute') {
      Data data = new Data();
      data.dateOfEvent = _selectedDay;
      data.message = message;
      data.isInEditMode = true;
      data.isInAdminMode = !isOfflineEvent(data.message, _selectedDay);
      data.subjects = chosenSubjects;
      data.onlineEvents = onlineEvents;

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EventViewerPage(
                  data: data,
                )),
      );
    } else {
      key.currentState.showSnackBar(new SnackBar(
        content: new Text("Das ist nicht dein Eintrag!"),
      ));
    }
  }

  void updateData(List<DocumentSnapshot> snapshot) async{
    List<Subject> subjectList = await SqliteDatabaseHelper.getChosenSubjects();
    List<Event> allOnlineEvents = FirestoreHelper.getEvents(snapshot, context);
    sqliteEvents = await SqliteDatabaseHelper.getEvents();

    onlineEvents = [];
    chosenSubjects = [];
    for(var i = 0; i < subjectList.length; i++){
      chosenSubjects.add(subjectList[i].name);
      for(var j = 0; j < allOnlineEvents.length; j++){
        if(subjectList[i].name == allOnlineEvents[j].subject){
          onlineEvents.add(allOnlineEvents[j]);
        }
      }
    }

    List<Event> allEventsWithMatchingSubject = [];
    allEventsWithMatchingSubject.addAll(sqliteEvents);
    allEventsWithMatchingSubject.addAll(onlineEvents);
    allEventsWithMatchingSubject.add(new Event('Heute', currentDateTime));
    setState(() {
      visibleEvents = eventsAsStrings = Converter.eventListToMap(allEventsWithMatchingSubject);
    });
  }
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        updateData(snapshot.data.documents);
        return Scaffold(
          key: key,
          appBar: AppBar(
            title: Text(widget.title),
          ),
          drawer: new DrawerOnly(),
          body: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              // Switch out 2 lines below to play with TableCalendar's settings
              //-----------------------
              _buildTableCalendar(),
              // _buildTableCalendarWithBuilders(),
              const SizedBox(height: 8.0),
              Expanded(child: _buildEventList()),
            ],
          ),
          floatingActionButton: new FloatingActionButton(
            onPressed: () => onWriteOwnMessageButtonPressed(context),
            tooltip: 'Eigene Nachricht erstellen',
            child: Icon(Icons.create),
          ),
        );
      },
    );
  }

  /// Simple TableCalendar configuration (using Styles) made with the calendar plugin
  Widget _buildTableCalendar() {
    return TableCalendar(
      events: visibleEvents,
      locale: 'de_CH',
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {CalendarFormat.month: 'Monate'},
      calendarStyle: CalendarStyle(
        selectedColor: Colors.deepOrange[400],
        todayColor: Colors.deepOrange[200],
        markersColor: Colors.brown[700],
      ),
      headerStyle: HeaderStyle(
        formatButtonTextStyle:
            TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
        formatButtonDecoration: BoxDecoration(
          color: Colors.deepOrange[400],
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      onDaySelected: _onDaySelected,
      onVisibleDaysChanged: _onVisibleDaysChanged,
    );
  }

  Widget _buildEventList() {
    return ListView(
      children: _selectedEvents
          .map((event) => Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0.8),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  title: Text(event.toString()),
                  onTap: () => onEventPressed(context, event),
                ),
              ))
          .toList(),
    );
  }
}
