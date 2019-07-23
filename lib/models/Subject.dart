import 'package:calendar1/services/sqliteDatabaseHelpers.dart';

/// A simple class to handle subjects.
class Subject implements Comparable<Subject>{
  String id;
  String name;
  bool isSelected;

  /// Compares to events based on their name
  int compareTo(Subject other){
    return name.compareTo(other.name);
  }

  /// Creates a map from a subject
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnMessage:name,
      columnIsSelected:isSelected,
      columnId:id
    };
    return map;
  }

  ///Creates an event based on a map
  Subject.fromMap(Map<String, dynamic> map) {
    isSelected = map[columnIsSelected];
    name=  map[columnName];
    id = map[columnId];
  }

  Subject(String id, String name, bool isSelecred) {
    this.name = name;
    this.isSelected = isSelecred;
    this.id = id;
  }
}
