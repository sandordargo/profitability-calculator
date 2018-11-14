import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:profitability_calculator/property_data.dart';
import 'package:profitability_calculator/sign_in_container.dart';
import 'package:profitability_calculator/prefs.dart';

class DataUploader {
  final List<PropertyData> data;
  SignInContainer _signInContainer = new SignInContainer();
  static bool  exporting = false;
  final BuildContext _scaffoldContext;

  DataUploader(this.data, this._scaffoldContext);

  void upload() {
    if (_signInContainer.getCurrentUser() != null) {
      if (!DataUploader.exporting) {
        DataUploader.exporting = true;
        Prefs.setBool("sync_needed", false);
        Prefs.setInt("last_sync", DateTime.now().millisecondsSinceEpoch);
        _exportData().then((status) {
          DataUploader.exporting = false;
          _showSnackbar(new Text(status == 200
              ? 'Data upload finished successfully'
              : "Data upload failed"));
        });
      }
    }
    else {
      _showSnackbar(Text("Login please for synching"));
    }
  }

  void _showSnackbar(Text content) {
    Scaffold.of(_scaffoldContext).showSnackBar(new SnackBar(content: content));
  }


  Future<int> _exportData() async {
    if (await _signInContainer.isSignedIn() == false) {
      _showSnackbar(Text("Login please for synching"));
      return 403;
    }

    var fileId = await getFileId();
    if (fileId == null) {
      fileId = await _createFile();
    }

    return _upload(fileId);
  }

  Future<String> _createFile() async {
    var myheaders = await _signInContainer.getCurrentUser().authHeaders;
    var mybody =
        "{\"name\": \"ProfitabilityCalulatorData.csv\", \"mimeType\": \"application/vnd.google-apps.spreadsheet\"}";

    myheaders["Content-Type"] = "application/json; charset=UTF-8";

    final http.Response response = await http.post(
        'https://www.googleapis.com/drive/v3/files',
        headers: myheaders,
        body: mybody);

    if (response.statusCode != 200) {
      _showSnackbar(Text("Data upload failed"));
      return null;
    }

    final Map<String, dynamic> data = json.decode(response.body);
    return data["id"];
  }

  String getDataToUpload() {
    String contents = "";
    String line = "";
    for (var property in data.reversed) {
      line = property.simplePrice.toString() +
          "," +
          property.simpleMonthlyRent.toString() +
          "," +
          property.simpleMonthlyCharges.toString() +
          "," +
          property.detailedPrice.toString() +
          "," +
          property.detailedCommission.toString() +
          "," +
          property.detailsNotaryFee.toString() +
          "," +
          property.detailedYearlyPropertyTax.toString() +
          "," +
          property.detailedMonthlyCharges.toString() +
          "," +
          property.detailedMonthlyRent.toString() +
          "\n";
      contents += line;
    }
    return contents;
  }

  Future<String> getFileId() async {
    final http.Response response = await http.get(
        'https://www.googleapis.com/drive/v3/files?q=name%3D%27ProfitabilityCalulatorData.csv%27',
        headers: await _signInContainer.getCurrentUser().authHeaders);
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

  Future<int> _upload(String fileId) async {
    if (fileId == null) {
      _showSnackbar(Text("Upload failed"));
      return 500;
    }
    final http.Response response = await http.patch(
        'https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media',
        headers: await _signInContainer.getCurrentUser().authHeaders,
        body: getDataToUpload());
    print("upload status ${response.statusCode}");
    return response.statusCode;
  }
}
