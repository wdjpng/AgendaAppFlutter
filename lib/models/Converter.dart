import 'package:calendar1/models/Event.dart';

class Converter{
  static eventListToMap(List<Event> eventList){
    /// Sorts the [eventList] based on their date.
    eventList.sort((a, b) => a.dateOfEvent.compareTo(b.dateOfEvent));

    List<String> messagesOnThisDay = [];

    Map<DateTime, List> eventMap = {};
    
    /// Adds all the events of one day to the events map.
    for (var i = 0; i < eventList.length; i++) {
      if (messagesOnThisDay.length > 0) {
        if (eventList[i - 1].dateOfEvent.year ==
            eventList[i].dateOfEvent.year &&
            eventList[i - 1].dateOfEvent.month ==
                eventList[i].dateOfEvent.month &&
            eventList[i - 1].dateOfEvent.day == eventList[i].dateOfEvent.day) {
          /// When the current day is the same as the one of the other messages
          /// on that day, the message also belongs to the [messagesOnThisDay].
          messagesOnThisDay.add(eventList[i].message);
        } else {
          /// The day of the current event is not equal to the one of the other
          /// messages in [messagesOnThisDay] thus messagesOnThisDay contains
          /// all the messages on that day and can be added to the events.
          ///
          /// Afterwards the [messagesOnThisDay] can be reset and the new event
          /// of the next day can be added to it.
          eventMap.putIfAbsent(
              eventList[i - 1].dateOfEvent, () => messagesOnThisDay);
          messagesOnThisDay = [];
          messagesOnThisDay.add(eventList[i].message);
        }
      } else {
        /// When the [messageOnThisDay] is empty we can just add a new message
        /// on a new day to it.
        messagesOnThisDay.add(eventList[i].message);
      }
    }

    /// This adds the last [messageOnThisDay] to the events.
    if (eventList.length != 0) {
      eventMap.putIfAbsent(
          eventList[eventList.length - 1].dateOfEvent, () => messagesOnThisDay);
    }

    return eventMap;
  }
}