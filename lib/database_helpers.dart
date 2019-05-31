import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'Event.dart';

// database table and column names
final String tableEvents = 'events';
final String columnId = '_id';
final String columnDateOfEvent = 'dateOfEvent';
final String columnMessage = 'message';

//Source: https://pusher.com/tutorials/local-data-flutter

// singleton class to manage the database
class DatabaseHelper {

  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "events.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 2;

  // Make this a singleton class.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only allow a single open connection to the database.
  static Database _database;
  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // open the database
  _initDatabase() async {
    // The path_provider plugin gets the right directory for Android or iOS.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // Open the database. Can also add an onUpdate callback parameter.
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
              CREATE TABLE $tableEvents (
                $columnId INTEGER PRIMARY KEY,
                $columnMessage TEXT NOT NULL,
                $columnDateOfEvent DATETIME NOT NULL
              )
              ''');
  }

  // Database helper methods:

  Future<int> insert(Event event) async {
    Database db = await database;
    int id = await db.insert(tableEvents, event.toMap());
    return id;
  }

  Future<List<Map>> getSavedEvents() async {
    Database db = await database;
    List<Map> maps = await db.query(tableEvents,
        columns: [columnId, columnDateOfEvent, columnMessage]);
    if (maps.length > 0) {
      return maps;
    }
    return null;
  }
}