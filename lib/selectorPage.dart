import 'package:flutter/material.dart';
import 'drawer.dart';

class SelectorPage extends StatelessWidget {
  @override
  Widget build(BuildContext ctxt) {
    return new Scaffold(
      drawer: new DrawerOnly(),    // new Line
      appBar: new AppBar(title: new Text("First Page"),),
      body: new Text("I belongs to First Page"),
    );
  }
}