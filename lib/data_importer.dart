import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:profitability_calculator/property_data.dart';
import 'package:profitability_calculator/property_database.dart';
import 'package:profitability_calculator/sign_in_container.dart';

import 'dart:convert';

class DataChangeNotification extends Notification {}

class DataImporter {
  final BuildContext _scaffoldContext;
  DataChangeNotification notifier = new DataChangeNotification();
  static bool importing = false;
  SignInContainer _signInContainer = new SignInContainer();

  DataImporter(this._scaffoldContext);

  void import() {
    if (_signInContainer.getCurrentUser() != null) {
      if (!DataImporter.importing) {
        DataImporter.importing = true;
        _handleImport().then((status) {
          DataImporter.importing = false;
          _showSnackbar(new Text(status == 200
              ? 'Data import finished successfully'
              : "Data import failed"));
        });
      }
    } else {
      _showSnackbar(Text("Login please for synching"));
    }
  }

  void _showSnackbar(Text content) {
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(content: content));
  }

  _handleImport() async {
    List<String> csvEntries = await _fetchData();
    _importData(csvEntries);
    if (_scaffoldContext != null) {
      _showSnackbar(new Text(csvEntries.isNotEmpty
          ? 'Data import finished successfully'
          : "Data import failed"));
      notifyParentAboutImport();
    }
  }

  void notifyParentAboutImport() {
    notifier.dispatch(_scaffoldContext);
  }

  void _importData(List<String> csvEntries) {
    if (csvEntries.isNotEmpty) {
      List<PropertyData> drinks = _extractPropertiesFromData(csvEntries);
      PropertyDatabase.get().deleteAll();
      _insertProperties(drinks);
    }
  }

  List<PropertyData> _extractPropertiesFromData(List<String> csvEntries) {
    List<PropertyData> properties = new List();
    removeHeaders(csvEntries);
    for (var line in csvEntries) {
      var fields = line.split(',');
      if (_isLineFilled(fields)) {
        properties.add(new PropertyData(
          int.parse(fields[0]),
          int.parse(fields[1]),
          int.parse(fields[2]),
          int.parse(fields[3]),
          int.parse(fields[4]),
          int.parse(fields[5]),
          int.parse(fields[6]),
          int.parse(fields[7]),
          int.parse(fields[8]),
          fields[9],
          fields[10],
        ));
      }
    }
    return properties;
  }

  bool _isLineFilled(List<String> fields) =>
      fields[1].trimLeft() != "-" && fields[1].isNotEmpty;

  void _insertProperties(List<PropertyData> properties) {
    for (var property in properties) {
      PropertyDatabase.get().insertProperty(property);
    }
  }

  void removeHeaders(List<String> csvEntries) {
    csvEntries.removeAt(0);
  }

  Future<List<String>> _fetchData() async {
    var fileId = await getFileId();
    final String url =
        'https://www.googleapis.com/drive/v3/files/$fileId/export?mimeType=text/csv';
    final http.Response response = await http.get(url,
        headers: await _signInContainer.getCurrentUser().authHeaders);
    if (response.statusCode != 200) {
      return new List<String>();
    }
    var csvUnformattedContent = response.body;
    var csvEntries = csvUnformattedContent.split("\n");
    return csvEntries;
  }

  Future<String> getFileId() async {
    final http.Response response = await http.get(
        'https://www.googleapis.com/drive/v3/files?q=name%3D%27AlcoholTrackerData.csv%27',
        headers: await _signInContainer.getCurrentUser().authHeaders);
    print("bod");
    print(response.body);
    final Map<String, dynamic> data = json.decode(response.body);
    return _pickFileId(data);
  }

  String _pickFileId(Map<String, dynamic> data) {
    final List<dynamic> files = data['files'];
    final Map<String, dynamic> fileData = files?.firstWhere(
      (dynamic contact) =>
          contact['mimeType'] == "application/vnd.google-apps.spreadsheet",
      orElse: () => null,
    );
    return fileData != null ? fileData["id"] : null;
  }
}
