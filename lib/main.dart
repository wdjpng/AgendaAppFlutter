import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Event.dart';


void main() {
  initializeDateFormatting().then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Table Calendar Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Table Calendar Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  DateTime _selectedDay;
  Map<DateTime, List> _events;
  Map<DateTime, List> _visibleEvents;
  List _selectedEvents;
  AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();


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

  void updateEvents(List<DocumentSnapshot> snapshot, BuildContext context){
    List<Event> newEvents = [];
    for(var i = 0; i < snapshot.length; i++){
      Event e = new Event(snapshot[i].data['message'], snapshot[i].data['dateOfEvent'].toDate());
      newEvents.add(e);
      //String b = snapshot[i].data['message'];
      //newEvents.add(new Event('a', 0, 'm', 's', 's', DateTime.now(), DateTime.now()));
    }

    newEvents.sort((a, b) => a.dateOfEvent.compareTo(b.dateOfEvent));

    List<String> messagesOnThisDay=[];

    for (var i = 0; i < newEvents.length; i++){
      if(messagesOnThisDay.length > 0){
        if(newEvents[i-1].dateOfEvent == newEvents[i].dateOfEvent){
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

    _visibleEvents = _events;
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
        );
      },
    );

  }

  // Simple TableCalendar configuration (using Styles)
  Widget _buildTableCalendar() {
    return TableCalendar(
      locale: 'en_US',
      events: _visibleEvents,
      initialCalendarFormat: CalendarFormat.week,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 weeks',
        CalendarFormat.week: 'Week',
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