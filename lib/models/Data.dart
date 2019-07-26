import 'package:calendar1/services/authentication.dart';
import 'Event.dart';

/// This class is used to transmit data in a single object.
class Data {
  Data();

  DateTime dateOfEvent = DateTime.now();
  String message = '';
  String url = 'flutter.io';
  bool isInEditMode = false;
  bool isInAdminMode;
  BaseAuth auth = new Auth();
  List<String> subjects = [];
  List<Event> onlineEvents = [];
}
