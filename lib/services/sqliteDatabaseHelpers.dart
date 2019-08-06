import 'dart:async';
import 'dart:io';

import 'package:calendar1/models/Event.dart';
import 'package:calendar1/pages/eventsPage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:calendar1/models/Subject.dart';

final String tableEvents = 'events';
final String columnId = 'id';
final String columnDateOfEvent = 'dateOfEvent';
final String columnMessage = 'message';

final String tableSubjects = 'subjects';
final String columnIsSelected = 'isSelected';
final String columnName = 'name';

/// Class to manage the sqlite database.
/// Source: https://pusher.com/tutorials/local-data-flutter.
class SqliteDatabaseHelper {
  /// This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "sqliteData.db";

  /// Increment this version when you need to change the schema.
  static final _databaseVersion = 5;

  SqliteDatabaseHelper._privateConstructor();

  static final SqliteDatabaseHelper instance =
  SqliteDatabaseHelper._privateConstructor();

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
                $columnId STRING PRIMARY KEY,
                $columnMessage TEXT NOT NULL,
                $columnDateOfEvent DATETIME NOT NULL
              )
              ''');
    await db.execute('''
              CREATE TABLE $tableSubjects (
                $columnId STRING PRIMARY KEY,
                $columnIsSelected BOOL NOT NULL,
                $columnName TEXT NOT NULL
              )
              ''');
  }

  /// Inserts event into sqlite database.
  insertEvent(Event event) async {
    event.dateOfEvent = new DateTime(event.dateOfEvent.year, event.dateOfEvent.month, event.dateOfEvent.day, 10);
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
  void updateSubject(String id, String name, bool isSelected) async {
    Database db = await database;
    List<Map> result =
        await db.rawQuery('SELECT * FROM subjects WHERE id=?', [id]);
    if (result.length == 0) {
      db.rawInsert('INSERT INTO subjects(name, isSelected, id) VALUES(?, ?, ?)',
          [name, false, id]);
    } else if (isSelected != null) {
      await db.rawUpdate(
          'UPDATE subjects SET isSelected = ?, name = ? WHERE id = ?' '',
          [isSelected, name, id]);
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
  void updateSubjectSelection(String id, bool newValue) async {
    Database db = await database;
    await db.rawUpdate(
        'UPDATE subjects SET isSelected = ? WHERE id = ?' '', [newValue, id]);
  }

  Future<List<Map>> getSavedSubjects() async {
    Database db = await database;
    List<Map> result = await db.query(tableSubjects);

    return result;
  }

  /// Reads events from the sqlite database and saves them to the [sqliteEvents]
  /// from the [EventsPageState] class.
  static Future<List<Event>> getEvents() async {
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;

    List<Map> maps = await helper.getSavedEvents() ?? List<Map>();
    List<Event> events = [];

    for (var i = 0; i < maps.length; i++) {
      /// Check whether all important elements of the event are not null
      if (maps[i][columnDateOfEvent] != null &&
          maps[i][columnMessage] != null) {
        events.add(Event.fromMap(maps[i]));
      }
    }

    return events;
  }

  /// Reads events from the sqlite database and saves them to the [sqliteEvents]
  /// from the [EventsPageState] class
  static Future<List<Subject>> getChosenSubjects() async {
    SqliteDatabaseHelper helper = SqliteDatabaseHelper.instance;
    List<Map> subjectMap = await helper.getSavedSubjects();
    List<Subject> subjectList = [];

    for (var i = 0; i < subjectMap.length; i++) {
      if (subjectMap[i][columnIsSelected] == 1) {
        subjectList.add(new Subject(subjectMap[i][columnId], subjectMap[i][columnName], true));
      }
    }

    return subjectList;
  }
}
