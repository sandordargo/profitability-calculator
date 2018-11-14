import 'package:flutter/material.dart';
import 'package:profitability_calculator/property_database.dart';
import 'package:profitability_calculator/data_importer.dart';
import 'package:profitability_calculator/data_uploader.dart';
import 'package:profitability_calculator/property_data.dart';
import 'dart:async';
import 'package:profitability_calculator/my_drawer.dart';
import 'package:profitability_calculator/prefs.dart';
import 'package:profitability_calculator/profitability_calculator.dart';
import 'package:intl/intl.dart';
import 'package:connectivity/connectivity.dart';
import 'package:url_launcher/url_launcher.dart';

class ListProperties extends StatefulWidget {
  ListProperties({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ListDrinksState createState() => new _ListDrinksState();
}

class _ListDrinksState extends State<ListProperties>
    with WidgetsBindingObserver {
  BuildContext _scaffoldContext;
  List<PropertyData> data = new List();
  Prefs prefs;
  final formatCurrency = new NumberFormat.currency(
      locale: 'fr_FR', name: 'EUR', symbol: '€', decimalDigits: 0);

  void addProperty() {
    Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) => new ProfitabilityCalculator(_scaffoldContext,
              title: "New calculation" /*_scaffoldContext*/)),
    );
  }

  Future<List<PropertyData>> getFromDb() async {
    return await PropertyDatabase.get().getAllProperties();
  }

  List<Widget> getWidgetList(
      List<PropertyData> properties, BuildContext context) {
    List<Widget> widgets = new List<Widget>();
    for (var property in properties) {
      print(property);
      widgets.add(new ListTile(
        leading: new IconButton(
            icon: new Icon(Icons.open_in_browser),
            onPressed: () {
              var url = property.URL;
              canLaunch(url).then((value) {
                if (value) {
                  launch(url);
                } else {
                  Scaffold.of(context).showSnackBar(
                      SnackBar(content: Text("Cannot open $url")));
                }
              });
            }),
        trailing: new Container(
          child: new IconButton(
            icon: new Icon(Icons.delete),
            onPressed: () {
              AlertDialog dialog = new AlertDialog(
                content: new Text(
                  "Do you really want to delete this drink?",
                  style: new TextStyle(fontSize: 30.0),
                ),
                actions: <Widget>[
                  new FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteProperty(property);
                      },
                      child: new Text('Yes')),
                  new FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: new Text('No')),
                ],
              );

              showDialog(context: context, builder: (context) => dialog);
            },
          ),
//              margin: const EdgeInsets.symmetric(horizontal: 0.5)
        ),
        title: new Text(
          '${formatCurrency.format(property.simplePrice != 0 ? property.simplePrice : property.detailedPrice)}',
          style: new TextStyle(fontWeight: FontWeight.w500, fontSize: 20.0),
        ),
        subtitle: new Text(
            'Rentability: ${property.calculateRentability().toStringAsPrecision(3)}%'),
        onTap: () {
          _editProperty(property);
        },
      ));
      widgets.add(new Divider());
    }
    return widgets;
  }

  bool _onNotification(dynamic notif) {
    if (isDataChangeNotification(notif)) {
      setState(() {});
    }
    _synchronizeAutomatically();
    return false;
  }

  bool isDataChangeNotification(notif) =>
      notif.toString() == "DataChangeNotification()";

  @override
  Widget build(BuildContext context) {
    return new NotificationListener(
        onNotification: _onNotification,
        child: new Scaffold(
          drawer: new MyDrawer(),
          appBar: new AppBar(
            title: new Text(widget.title),
            actions: <Widget>[
              new IconButton(
                  icon: new Icon(Icons.sync), onPressed: _synchronize),
            ],
          ),
          body: new Center(
              child: new FutureBuilder<List<PropertyData>>(
            future: getFromDb(),
            builder: (BuildContext context,
                AsyncSnapshot<List<PropertyData>> snapshot) {
              this._scaffoldContext = context;
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return makeNewProgressIndicator();
                case ConnectionState.waiting:
                  return makeNewProgressIndicator();
                default:
                  if (!snapshot.hasError) {
                    this.data = snapshot.data;
                    return new Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        new Expanded(
                            child: new ListView(
                                children:
                                    getWidgetList(snapshot.data, context))),
                      ],
                    );
                  }
                  return new ListView(
                      children: <Widget>[new Text(snapshot.error.toString())]);
              }
            },
          )),
          floatingActionButton: new FloatingActionButton(
            onPressed: addProperty,
            tooltip: 'Register new consumption',
            child: new Icon(Icons.add),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }

  Widget makeNewProgressIndicator() {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        new Container(
          child: new CircularProgressIndicator(),
          margin: EdgeInsets.symmetric(vertical: 20.0),
        ),
        new Text("Loading data...")
      ],
    );
  }

  void _deleteProperty(item) {
    setState(() {
      PropertyDatabase.get().deleteDrink(item);
      Prefs.setBool("sync_needed", true);
//      _synchronizeAutomatically();
    });
  }

  void _editProperty(item) {
    Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) => new ProfitabilityCalculator(_scaffoldContext,
              title: "Edit property", property: item)),
    );
  }

  void _synchronizeAutomatically() async {
    List<PropertyData> properties =
        await PropertyDatabase.get().getAllProperties();
    var lastSynch = await Prefs.getIntF("last_sync");
    var lastSynchDate = new DateTime.fromMillisecondsSinceEpoch(lastSynch);
    if ((await Prefs.getBoolF("sync_needed") &&
            lastSynchDate
                .add(new Duration(seconds: 10))
                .isBefore(new DateTime.now())) ||
        data.isEmpty && properties.isEmpty) {
      var connectivityResult = await (new Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.wifi) {
        _synchronize(properties: properties);
      }
    }
  }

  void _synchronize({List<PropertyData> properties}) async {
    if (properties == null) {
      properties = await PropertyDatabase.get().getAllProperties();
    }
    if (data.isEmpty && properties.isEmpty) {
      var importer = new DataImporter(_scaffoldContext);
      importer.import();
    } else {
      var uploader = DataUploader(properties, _scaffoldContext);
      uploader.upload();
    }
  }
}
