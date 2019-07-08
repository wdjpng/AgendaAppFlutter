import 'database_helpers.dart';

/// A simple class to handle events.
class Event implements Comparable<Event>{
  String publisher;
  int type;
  int id;
  String schoolSubject;
  String subject;
  String message;
  DateTime datePublished;
  DateTime dateOfEvent;

  /// Compares to events based on their date
  int compareTo(Event other){
    return dateOfEvent.compareTo(other.dateOfEvent);
  }


  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnMessage:message,
      columnDateOfEvent: dateOfEvent.toIso8601String()
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }

  ///Creates an event based on a map
  Event.fromMap(Map<String, dynamic> map) {
    dateOfEvent= DateTime.parse(map[columnDateOfEvent]);
    message=  map[columnMessage];
    subject = map[subject];
    id = map[columnId];
  }


  Event( String message, DateTime dateOfEvent) {
    this.type = type;
    this.publisher = publisher;
    this.schoolSubject = schoolSubject;
    this.subject = subject;
    this.message = message;
    this.dateOfEvent = dateOfEvent;
    this.datePublished = datePublished;
  }


}
