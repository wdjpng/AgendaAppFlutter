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

final String tableSubjects = 'subjects';
final String columnIsSelected = 'isSelected';
final String columnName = 'name';

//Source: https://pusher.com/tutorials/local-data-flutter

// singleton class to manage the database
class DatabaseHelper {

  // This is the actual database filename that is saved in the docs directory.
  static final _databaseName = "sqliteData.db";
  // Increment this version when you need to change the schema.
  static final _databaseVersion = 3;

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
    await db.execute('''
              CREATE TABLE $tableSubjects (
                $columnIsSelected BOOL NOT NULL,
                $columnName TEXT NOT NULL
              )
              ''');
  }

  // Database helper methods:

  insertEvent(Event event) async {
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
  
  insertSubjectIfAbsent(String name) async {
    Database db = await database;
    List<Map> result = await db.rawQuery('SELECT * FROM subjects WHERE name=?', [name]);
    if(result.length==0){
      db.rawInsert('INSERT INTO subjects(name, isSelected) VALUES(?, ?)', [name, false]);
    }
  }

  updateSubjectSelection(String name, bool newValue) async {
    Database db = await database;
    await db.rawUpdate('UPDATE subjects SET isSelected = ? WHERE name = ?''', [newValue, name]);
  }

  Future<List<Map>> getSavedSubjects() async {
    Database db = await database;
    List<Map> result = await db.query(tableSubjects);

    return result;

  }
}