import 'package:calendar1/models/Event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final String tableEvents = 'events';
final String columnId = 'id';
final String columnDateOfEvent = 'dateOfEvent';
final String columnMessage = 'message';

final String tableSubjects = 'subjects';
final String columnIsSelected = 'isSelected';
final String columnName = 'name';

class FirestoreHelper {
  /// Updates the visible events based on the online firestore and the offline
  /// sqlite events.
  static List<Event> getEvents(
      List<DocumentSnapshot> snapshot, BuildContext context) {
    List<Event> events = [];

    /// Adds the online events that have the correct subjects to the new events.
    for (var i = 0; i < snapshot.length; i++) {
      /// Creates the new potential event basedt on the online event.
      Event newEvent = new Event(snapshot[i].data['message'],
          snapshot[i].data['dateOfEvent'].toDate());
      newEvent.subject = snapshot[i].data['subject'];
      newEvent.id = snapshot[i].documentID;
      newEvent.lastUpdate = snapshot[i].data['lastUpdate'].toDate();

      events.add(newEvent);
    }

    return events;
  }

  static void pushEvent(String message, DateTime dateOfEvent, String subject,
      String publisherUid) async {
    dateOfEvent =
        new DateTime(dateOfEvent.year, dateOfEvent.month, dateOfEvent.day, 10);
    Firestore.instance.collection('events').document().setData({
      'message': message,
      'dateOfEvent': dateOfEvent,
      'subject': subject,
      'lastUpdate': DateTime.now(),
      'publisherUid': publisherUid
    });
  }

  static void updateEvent(Event oldEvent, Event newEvent, List<Event> events) {
    String idOfEvent = "";

    for (var i = 0; i < events.length; i++) {
      if (oldEvent.areDateAndMessageEqual(events[i])) {
        idOfEvent = events[i].id;
        break;
      }
    }

    if (idOfEvent != "") {
      Firestore.instance.collection('events').document(idOfEvent).updateData({
        'message': newEvent.message,
        'dateOfEvent': newEvent.dateOfEvent,
        'subject': newEvent.subject,
        'lastUpdate': DateTime.now()
      });
    }
  }

  static void deleteEvent(Event event, List<Event> onlineEvents) {
    String idOfEvent = "";

    for (var i = 0; i < onlineEvents.length; i++) {
      if (event.areDateAndMessageEqual(onlineEvents[i])) {
        idOfEvent = onlineEvents[i].id;
        break;
      }
    }

    if (idOfEvent != "") {
      Firestore.instance.collection('events').document(idOfEvent).delete();
    }
  }
}
