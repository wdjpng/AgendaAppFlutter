import 'package:calendar1/models/Event.dart';
import 'package:calendar1/widgets/eventsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'sqliteDatabaseHelpers.dart';

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
  static void updateEvents(
      List<DocumentSnapshot> snapshot, BuildContext context) {
    List<Event> newEvents = [];
    EventsPageState.events = Map<DateTime, List>();

    //TODO clearly split these those database types
    SqliteDatabaseHelper.readEvents();

    /// This is used to pass by value and not by reference
    newEvents.insertAll(0, EventsPageState.sqliteEvents);

    /// Adds the online events that have the correct subjects to the new events.
    for (var i = 0; i < snapshot.length; i++) {
      /// Creates the new potential event basedt on the online event.
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