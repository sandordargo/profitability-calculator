import 'package:flutter/material.dart';
import 'package:profitability_calculator/my_drawer.dart';
import 'package:profitability_calculator/property_database.dart';
import 'package:profitability_calculator/property_data.dart';
import 'package:profitability_calculator/prefs.dart';
import 'package:profitability_calculator/url_validator.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfitabilityCalculator extends StatefulWidget {
  ProfitabilityCalculator(this._scaffoldContext,
      {Key key, this.title, this.property})
      : super(key: key);
  final String title;
  final BuildContext _scaffoldContext;
  final PropertyData property;

  @override
  _ProfitabilityCalculatorState createState() =>
      new _ProfitabilityCalculatorState(this._scaffoldContext,
          property: this.property);
}

class _ProfitabilityCalculatorState extends State<ProfitabilityCalculator>
    with SingleTickerProviderStateMixin {
  PropertyData property;
  double profitability;
  RichText profitabilityText = new RichText(
    text: new TextSpan(
      style: new TextStyle(
        fontSize: 16.0,
        color: Colors.black,
      ),
      children: <TextSpan>[
        new TextSpan(text: 'Fill the form to get potential rentability '),
      ],
    ),
  );

  TextEditingController simplePriceController;
  TextEditingController simpleMonthlyRentController;
  TextEditingController simpleMonthlyChargesController;
  TextEditingController priceController;
  TextEditingController commissionController;
  TextEditingController notaryFeeController;
  TextEditingController monthlyRentController;
  TextEditingController monthlyChargesController;
  TextEditingController propertyTaxesController;
  TextEditingController urlController;
  TextEditingController remarkTextController;
  TabController _tabController;
  int _selectedTab = 0;
  final BuildContext _scaffoldContext;
  final _simpleFormKey = GlobalKey<FormState>();
  final _detaildedFormKey = GlobalKey<FormState>();
  int id;

  _ProfitabilityCalculatorState(this._scaffoldContext, {this.property}) {
    simplePriceController = new TextEditingController(
        text: property == null ? null : property.simplePrice.toString());
    simpleMonthlyRentController = new TextEditingController(
        text: property == null ? null : property.simpleMonthlyRent.toString());
    simpleMonthlyChargesController = new TextEditingController(
        text:
            property == null ? null : property.simpleMonthlyCharges.toString());
    priceController = new TextEditingController(
        text: property == null ? null : property.detailedPrice.toString());
    commissionController = new TextEditingController(
        text: property == null ? null : property.detailedCommission.toString());
    notaryFeeController = new TextEditingController(
        text: property == null ? null : property.detailsNotaryFee.toString());
    monthlyRentController = new TextEditingController(
        text:
            property == null ? null : property.detailedMonthlyRent.toString());
    monthlyChargesController = new TextEditingController(
        text: property == null
            ? null
            : property.detailedMonthlyCharges.toString());
    propertyTaxesController = new TextEditingController(
        text: property == null
            ? null
            : property.detailedYearlyPropertyTax.toString());
    _selectedTab =
        simplePriceController.text == "0" && priceController.text != "0"
            ? 1
            : 0;
    urlController =
        new TextEditingController(text: property == null ? null : property.URL);
    remarkTextController = new TextEditingController(
        text: property == null ? null : property.remark);
    if (this.property != null) {
      this.id = this.property.id;
    }
    print(_selectedTab);
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        new TabController(vsync: this, length: 2, initialIndex: _selectedTab);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      if (movedToDetailedTab()) {
        fillDetailedFromSimple();
      } else if (movedToSimpleTab()) {
        fillSimpleFromDetailed();
      }
      _selectedTab = _tabController.index;
    });
  }

  void fillSimpleFromDetailed() {
    simplePriceController.text = priceController.text;
    simpleMonthlyRentController.text = monthlyRentController.text;
    simpleMonthlyChargesController.text = monthlyChargesController.text;
    calculateFromSimpleData();
  }

  void fillDetailedFromSimple() {
    priceController.text = simplePriceController.text;
    monthlyRentController.text = simpleMonthlyRentController.text;
    monthlyChargesController.text = simpleMonthlyChargesController.text;
    calculateFromDetailedData();
  }

  bool movedToSimpleTab() => _selectedTab == 1 && _tabController.index == 0;

  bool movedToDetailedTab() => _selectedTab == 0 && _tabController.index == 1;

  void calculateFromSimpleData() {
    setState(() {
      var yearlyRent = double.parse(simpleMonthlyRentController.text) * 12;
      var yearlyCosts = double.parse(simpleMonthlyRentController.text) +
          double.parse(simpleMonthlyChargesController.text) * 12;
      var oneTimeCosts = double.parse(simplePriceController.text) * 1.07;
      var rentability = (yearlyRent - yearlyCosts) / oneTimeCosts * 100;

      profitabilityText = makeRentabilityText(rentability);
    });
  }

  void calculateFromDetailedData() {
    setState(() {
      var yearlyRent = double.parse(monthlyRentController.text) * 12;
      var yearlyCosts = double.parse(monthlyChargesController.text) * 12 +
          double.parse(propertyTaxesController.text);
      var oneTimeCosts = double.parse(priceController.text) +
          double.parse(notaryFeeController.text) +
          double.parse(commissionController.text);
      var rentability = (yearlyRent - yearlyCosts) / oneTimeCosts * 100;

      profitabilityText = makeRentabilityText(rentability);
    });
  }

  RichText makeRentabilityText(double rentability) {
    return new RichText(
      text: new TextSpan(
        style: new TextStyle(
          fontSize: 20.0,
          color: Colors.black,
        ),
        children: <TextSpan>[
          new TextSpan(text: 'Potential rentability is '),
          new TextSpan(
              text: "${rentability.toStringAsPrecision(2)} %",
              style: new TextStyle(
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  void openUrl() async {
    var url = urlController.text;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Scaffold.of(context).showSnackBar(
          SnackBar(content: Text("Cannot open $url")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      drawer: new MyDrawer(),
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.add),
            ),
            Tab(
              icon: Icon(Icons.details),
            )
          ],
        ),
      ),
      body: new Builder(
    builder: (BuildContext context) {
    return new
    TabBarView(
        controller: _tabController,
        children: [
          new Form(
              key: _simpleFormKey,
              child: new Center(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the price of the property';
                          }
                        },
                        onEditingComplete: calculateFromSimpleData,
                        controller: simplePriceController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Price of the property?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the estimated monthly rental';
                          }
                        },
                        onEditingComplete: calculateFromSimpleData,
                        controller: simpleMonthlyRentController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Planned monthly rental income?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the amount of monthly charges';
                          }
                        },
                        onEditingComplete: calculateFromSimpleData,
                        controller: simpleMonthlyChargesController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Monthly charges?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isNotEmpty && !isURL(value)) {
                            return 'Add a valid URL';
                          }
                        },
                        controller: urlController,
                        keyboardType: TextInputType.text,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            labelText: 'URL of the property ad',
                            suffixIcon: IconButton(
                                icon: Icon(Icons.open_in_browser),
                                onPressed: openUrl
                            )),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        controller: remarkTextController,
                        keyboardType: TextInputType.text,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Add your remarks here'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: profitabilityText,
                    ),
                    new Container(
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Container(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: new RaisedButton(
                                  onPressed: () {
                                    if (!_simpleFormKey.currentState
                                        .validate()) {
                                      return null;
                                    }
                                    save(context);
                                  },
                                  child: new Text(
                                    "Save",
                                    style: new TextStyle(color: Colors.white),
                                  ),
                                  color: Colors.green)),
                          new Container(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: new RaisedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: new Text('Cancel',
                                    style: new TextStyle(color: Colors.white)),
                                color: Colors.red,
                              ))
                        ],
                      ),
                    )
                  ],
                ),
              )),
          new Form(
              key: _detaildedFormKey,
              child: new Center(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the price of the property';
                          }
                        },
                        onEditingComplete: calculateFromDetailedData,
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Price of the property?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the amount of agency commission';
                          }
                        },
                        onEditingComplete: calculateFromDetailedData,
                        controller: commissionController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Agency commission?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the amount of the notary\'s fee';
                          }
                        },
                        onEditingComplete: calculateFromDetailedData,
                        controller: notaryFeeController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Notary fee?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the estimated monthly rental';
                          }
                        },
                        onEditingComplete: calculateFromDetailedData,
                        controller: monthlyRentController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Planned monthly rental income?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the monthly charges';
                          }
                        },
                        onEditingComplete: calculateFromDetailedData,
                        controller: monthlyChargesController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Monthly charges?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Enter the yearly property tax';
                          }
                        },
                        onEditingComplete: calculateFromDetailedData,
                        controller: propertyTaxesController,
                        keyboardType: TextInputType.number,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            suffixText: "€",
                            labelText: 'Yearly property tax?'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        validator: (value) {
                          if (value.isNotEmpty && !isURL(value)) {
                            return 'Add a valid URL';
                          }
                        },
                        controller: urlController,
                        keyboardType: TextInputType.text,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            labelText: 'URL of the property ad',
                            suffixIcon: IconButton(
                                icon: Icon(Icons.open_in_browser),
                                onPressed: openUrl
                            )
                        ),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: new TextFormField(
                        controller: remarkTextController,
                        keyboardType: TextInputType.text,
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Add your remarks here'),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: profitabilityText,
                    ),
                    new Container(
                      child: new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new Container(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: new RaisedButton(
                                  onPressed: () {
                                    if (!_detaildedFormKey.currentState
                                        .validate()) {
                                      return null;
                                    }
                                    save(context);
                                  },
                                  child: new Text(
                                    "Save",
                                    style: new TextStyle(color: Colors.white),
                                  ),
                                  color: Colors.green)),
                          new Container(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: new RaisedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: new Text('Cancel',
                                    style: new TextStyle(color: Colors.white)),
                                color: Colors.red,
                              ))
                        ],
                      ),
                    )
                  ],
                ),
              ))
        ],
      );})

    );
  }

  void save(BuildContext context) {
    Navigator.pop(context);
    var db = PropertyDatabase.get();
    PropertyData property = new PropertyData(
        simplePriceController.text.isNotEmpty
            ? int.parse(simplePriceController.text)
            : 0,
        simpleMonthlyRentController.text.isNotEmpty
            ? int.parse(simpleMonthlyRentController.text)
            : 0,
        simpleMonthlyChargesController.text.isNotEmpty
            ? int.parse(simpleMonthlyChargesController.text)
            : 0,
        priceController.text.isNotEmpty ? int.parse(priceController.text) : 0,
        notaryFeeController.text.isNotEmpty
            ? int.parse(notaryFeeController.text)
            : 0,
        commissionController.text.isNotEmpty
            ? int.parse(commissionController.text)
            : 0,
        monthlyRentController.text.isNotEmpty
            ? int.parse(monthlyRentController.text)
            : 0,
        monthlyChargesController.text.isNotEmpty
            ? int.parse(monthlyChargesController.text)
            : 0,
        propertyTaxesController.text.isNotEmpty
            ? int.parse(propertyTaxesController.text)
            : 0,
        urlController.text,
        remarkTextController.text);
    property.id = this.id;
    db.upsertDrink(property);
    Prefs.setBool("sync_needed", true);
    Scaffold.of(_scaffoldContext).setState(() {
      print("Adding new drink");
    });
    Scaffold.of(_scaffoldContext).showSnackBar(SnackBar(
        content: new Text(
            "You saved a new poperty whose price is ${property.simplePrice.toString()}")));
  }
}
