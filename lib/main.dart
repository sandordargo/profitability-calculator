import 'package:flutter/material.dart';
import 'package:profitability_calculator/list_properties.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Profitability Calculator',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new ListProperties(title: 'Profitability Calculator'),
    );
  }
}

