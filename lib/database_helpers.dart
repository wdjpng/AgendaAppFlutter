import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'Event.dart';
import 'eventsPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final String tableEvents = 'events';
final String columnId = '_id';
final String columnDateOfEvent = 'dateOfEvent';
final String columnMessage = 'message';

final String tableSubjects = 'subjects';
final String columnIsSelected = 'isSelected';
final String columnName = 'name';

/// Class to manage the sqlite database.
/// Source: https://pusher.com/tutorials/local-data-flutter.
class DatabaseHelper {
  /// This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "sqliteData.db";

  /// Increment this version when you need to change the schema.
  static final _databaseVersion = 3;

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  /// Opens the database.
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  /// Creates the subjects and events database tables.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
              CREATE TABLE $tableEvents (
                $columnId INTEGER PRIMARY KEY,
                $columnMessage TEXT NOT NULL,
                $columnDateOfEvent DATETIME NOT NULL
              )
              ''');
    await db.execute('''
              CREATE TABLE $tableSubjects (
                $columnIsSelected BOOL NOT NULL,
                $columnName TEXT NOT NULL
              )
              ''');
  }

  /// Inserts event into sqlite database.
  insertEvent(Event event) async {
    Database db = await database;
    int id = await db.insert(tableEvents, event.toMap());
    return id;
  }

  /// Returns the saved offline sqlite events.
  Future<List<Map>> getSavedEvents() async {
    Database db = await database;
    List<Map> events = await db.query(tableEvents,
        columns: [columnId, columnDateOfEvent, columnMessage]);
    if (events.length > 0) {
      return events;
    }
    return null;
  }

  /// If the subject is not in the database it will be added as an unselected
  /// subject.
  void insertSubjectIfAbsent(String name) async {
    Database db = await database;
    List<Map> result =
        await db.rawQuery('SELECT * FROM subjects WHERE name=?', [name]);
    if (result.length == 0) {
      db.rawInsert(
          'INSERT INTO subjects(name, isSelected) VALUES(?, ?)', [name, false]);
    }
  }

  //TODO for deleteEvent and updateEvent also use ID, or at least date
  /// Deletes event from the offline sqlite database based on its message.
  deleteEvent(String message) async {
    Database db = await database;
    return db.delete(tableEvents, where: 'message = ?', whereArgs: [message]);
  }

  /// Updates event from the offline sqlite database based on its message.
  void updateEvent(String originalMessage, String newMessage,
      DateTime newDateOfEvent) async {
    Database db = await database;
    await db.update(
        tableEvents,
        {
          'message': newMessage,
          'dateOfEvent': newDateOfEvent.toIso8601String()
        },
        where: 'message = ?',
        whereArgs: [originalMessage]);
  }

  /// Updates whether a subject is selected based on its name.
  void updateSubjectSelection(String name, bool newValue) async {
    Database db = await database;
    await db.rawUpdate('UPDATE subjects SET isSelected = ? WHERE name = ?' '',
        [newValue, name]);
  }

  Future<List<Map>> getSavedSubjects() async {
    Database db = await database;
    List<Map> result = await db.query(tableSubjects);

    return result;
  }

  /// Reads events from the sqlite database and saves them to the [sqliteEvents]
  /// from the [EventsPageState] class.
  static readEvents() async {
    DatabaseHelper helper = DatabaseHelper.instance;

    List<Map> maps = await helper.getSavedEvents() ?? List<Map>();
    EventsPageState.sqliteEvents = [];

    for (var i = 0; i < maps.length; i++) {
      /// Check whether all important elements of the event are not null
      if (maps[i][columnDateOfEvent] != null &&
          maps[i][columnMessage] != null) {
        EventsPageState.sqliteEvents.add(Event.fromMap(maps[i]));
      }
    }

    return EventsPageState.sqliteEvents;
  }

  /// Reads events from the sqlite database and saves them to the [sqliteEvents]
  /// from the [EventsPageState] class
  static readChosenSubjects() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    List<Map> subjects = await helper.getSavedSubjects();

    EventsPageState.chosenSubjects = List<String>();

    for (var i = 0; i < subjects.length; i++) {
      if (subjects[i][columnIsSelected] == 1) {
        EventsPageState.chosenSubjects.add(subjects[i][columnName]);
      }
    }
  }

  /// Updates the visible events based on the online firestore and the offline
  /// sqlite events.
  static void updateEvents(
      List<DocumentSnapshot> snapshot, BuildContext context) {
    List<Event> newEvents = [];
    EventsPageState.events = Map<DateTime, List>();

    DatabaseHelper.readEvents();
    newEvents = EventsPageState.sqliteEvents;

    /// Adds the online events that have the correct subjects to the new events.
    for (var i = 0; i < snapshot.length; i++) {
      /// Creates the new potential event based on the online event.
      Event potentialEvent = new Event(snapshot[i].data['message'],
          snapshot[i].data['dateOfEvent'].toDate());
      potentialEvent.subject = snapshot[i].data['subject'];

      /// Adds the event to the [newEvents].
      for (var i = 0; i < EventsPageState.chosenSubjects.length; i++) {
        if (EventsPageState.chosenSubjects[i] == potentialEvent.subject) {
          newEvents.add(potentialEvent);
          break;
        }
      }
    }

    /// Sorts the [newEvents] based on their date.
    newEvents.sort((a, b) => a.dateOfEvent.compareTo(b.dateOfEvent));

    List<String> messagesOnThisDay = [];

    /// Adds all the events of one day to the events map.
    for (var i = 0; i < newEvents.length; i++) {
      if (messagesOnThisDay.length > 0) {
        if (newEvents[i - 1].dateOfEvent.year ==
                newEvents[i].dateOfEvent.year &&
            newEvents[i - 1].dateOfEvent.month ==
                newEvents[i].dateOfEvent.month &&
            newEvents[i - 1].dateOfEvent.day == newEvents[i].dateOfEvent.day) {
          /// When the current day is the same as the one of the other messages
          /// on that day, the message also belongs to the [messagesOnThisDay].
          messagesOnThisDay.add(newEvents[i].message);
        } else {
          /// The day of the current event is not equal to the one of the other
          /// messages in [messagesOnThisDay] thus messagesOnThisDay contains
          /// all the messages on that day and can be added to the events.
          ///
          /// Afterwards the [messagesOnThisDay] can be reset and the new event
          /// of the next day can be added to it.
          EventsPageState.events.putIfAbsent(
              newEvents[i - 1].dateOfEvent, () => messagesOnThisDay);
          messagesOnThisDay = [];
          messagesOnThisDay.add(newEvents[i].message);
        }
      } else {
        /// When the [messageOnThisDay] is empty we can just add a new message
        /// on a new day to it.
        messagesOnThisDay.add(newEvents[i].message);
      }
    }

    /// This adds the last [messageOnThisDay] to the events.
    if (newEvents.length != 0) {
      EventsPageState.events.putIfAbsent(
          newEvents[newEvents.length - 1].dateOfEvent, () => messagesOnThisDay);
    }

    /// Because we have used putIfAbsent but there always is the event
    /// 'Today', we have to merge today's messages with the event 'Today'.
    EventsPageState.events[currentDateTime] = ['Heute'];
    for (var i = 0; i < EventsPageState.events.keys.length; i++) {
      /// If one of the key's days is today, the messages will be merged together.
      if (EventsPageState.events.keys.elementAt(i).year ==
              currentDateTime.year &&
          EventsPageState.events.keys.elementAt(i).month ==
              currentDateTime.month &&
          EventsPageState.events.keys.elementAt(i).day == currentDateTime.day &&
          EventsPageState.events.keys.elementAt(i) != currentDateTime) {
        EventsPageState.events[currentDateTime] = ['Heute'];
        EventsPageState.events[currentDateTime].insertAll(0,
            EventsPageState.events[EventsPageState.events.keys.elementAt(i)]);
        EventsPageState.events.remove(EventsPageState.events.keys.elementAt(i));
        break;
      }
    }

    EventsPageState.visibleEvents = EventsPageState.events;
  }
}
