class Event implements Comparable<Event>{
  String publisher;
  int type;
  String schoolSubject;
  String subject;
  String message;
  DateTime datePublished;
  DateTime dateOfEvent;

  int compareTo(Event other){
    return dateOfEvent.compareTo(other.dateOfEvent);
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
