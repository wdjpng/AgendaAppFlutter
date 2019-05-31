import 'database_helpers.dart';

class Event implements Comparable<Event>{
  String publisher;
  int type;
  int id;
  String schoolSubject;
  String subject;
  String message;
  DateTime datePublished;
  DateTime dateOfEvent;

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

  Event.fromMap(Map<String, dynamic> map) {
    dateOfEvent= DateTime.parse(map[columnDateOfEvent]);
    message=  map[columnMessage];
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
