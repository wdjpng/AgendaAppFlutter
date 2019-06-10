import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Event.dart';
import 'uploaderPage.dart';
import 'Data.dart';
import 'database_helpers.dart';
import 'drawer.dart';

DateTime currentDateTime = DateTime.now();
class EventsPage extends StatefulWidget {
  EventsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with TickerProviderStateMixin {
  DateTime _selectedDay;
  Map<DateTime, List> _events;
  Map<DateTime, List> _visibleEvents;
  List<Event> sqliteEvents = List<Event>();

  List _selectedEvents;
  AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _selectedDay = currentDateTime;


    _events = {
      _selectedDay: ['Heute']
    };

    _selectedEvents = _events[_selectedDay] ?? [];
    _visibleEvents = _events;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _controller.forward();
  }

  void _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedDay = day;
      _selectedEvents = events;
    });

    print('Selected day: $day');
  }

  void _onVisibleDaysChanged(DateTime first, DateTime last,
      CalendarFormat format) {
    setState(() {
      _visibleEvents = Map.fromEntries(
        _events.entries.where(
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

  _read() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    List<Map> maps = await helper.getSavedEvents() ?? List<Map>();


    List<Event> tmp = sqliteEvents;
    for(var i = 0; i < maps.length; i++){
      if(maps[i][columnDateOfEvent]!=null && maps[i][columnMessage]!=null){
        sqliteEvents.add(Event.fromMap(maps[i]));
        if(sqliteEvents[sqliteEvents.length-1].message == null || sqliteEvents[sqliteEvents.length-1].dateOfEvent == null){
          sqliteEvents=tmp;
          break;
        }
      }
    }



  }


  void updateEvents(List<DocumentSnapshot> snapshot, BuildContext context){
    List<Event> newEvents = [];
    _read();
    if(sqliteEvents!=null){
      newEvents.addAll(sqliteEvents);
    }

    for(var i = 0; i < snapshot.length; i++){
      Event e = new Event(snapshot[i].data['message'], snapshot[i].data['dateOfEvent'].toDate());
      newEvents.add(e);
    }

    for(var i = 0; i < newEvents.length; i++){
      if(newEvents[i].message == null || newEvents[i].dateOfEvent == null){
        newEvents.removeAt(i);
        i--;
      }
    }

    newEvents.sort((a, b) => a.dateOfEvent.compareTo(b.dateOfEvent));

    List<String> messagesOnThisDay=[];

    for (var i = 0; i < newEvents.length; i++){
      if(messagesOnThisDay.length > 0){
        if(newEvents[i-1].dateOfEvent.year == newEvents[i].dateOfEvent.year &&
            newEvents[i-1].dateOfEvent.month == newEvents[i].dateOfEvent.month &&
            newEvents[i-1].dateOfEvent.day == newEvents[i].dateOfEvent.day){
          messagesOnThisDay.add(newEvents[i].message);
        } else{
          _events.putIfAbsent(newEvents[i-1].dateOfEvent, () => messagesOnThisDay);
          messagesOnThisDay=[];
          messagesOnThisDay.add(newEvents[i].message);
        }
      } else{
        messagesOnThisDay.add(newEvents[i].message);
      }
    }
    if(newEvents.length !=0){
      _events.putIfAbsent(newEvents[newEvents.length-1].dateOfEvent, () => messagesOnThisDay);
    }
    
    for (var i = 0; i < _events.keys.length; i++){
      if(_events.keys.elementAt(i).year == currentDateTime.year &&
          _events.keys.elementAt(i).month == currentDateTime.month &&
          _events.keys.elementAt(i).day == currentDateTime.day && _events.keys.elementAt(i) != currentDateTime){
        _events[currentDateTime].insertAll(0, _events[_events.keys.elementAt(i)]);
        _events.remove(_events.keys.elementAt(i));
        break;
      }
    }

    _visibleEvents = _events;
  }


  void onWriteOwnMessageButtonPressed(BuildContext context){
    Data data = new Data(_selectedDay);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploaderPage(data: data,)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        updateEvents(snapshot.data.documents, context);
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
          ),
          drawer:new DrawerOnly(),
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
          ), floatingActionButton: new FloatingActionButton(
            onPressed: () => onWriteOwnMessageButtonPressed(context),
            tooltip: 'Eigene Nachricht erstellen',
            child: Icon(Icons.create),
        ),
        );
      },
    );

  }

  // Simple TableCalendar configuration (using Styles)
  Widget _buildTableCalendar() {
    return TableCalendar(
      events: _visibleEvents,
      initialCalendarFormat: CalendarFormat.week,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Monate',
        CalendarFormat.twoWeeks: '2 Wochen',
        CalendarFormat.week: 'Woche',
      },
      calendarStyle: CalendarStyle(
        selectedColor: Colors.deepOrange[400],
        todayColor: Colors.deepOrange[200],
        markersColor: Colors.brown[700],
      ),
      headerStyle: HeaderStyle(
        formatButtonTextStyle: TextStyle().copyWith(
            color: Colors.white, fontSize: 15.0),
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
          .map((event) =>
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 0.8),
              borderRadius: BorderRadius.circular(12.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(event.toString()),
              onTap: () => print('$event tapped!'),
            ),
          ))
          .toList(),
    );
  }
}