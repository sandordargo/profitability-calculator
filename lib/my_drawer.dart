import 'package:flutter/material.dart';
import 'package:profitability_calculator/list_properties.dart';
import 'package:profitability_calculator/hyperlink_text_span.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:profitability_calculator/sign_in_container.dart';

class MyDrawer extends StatefulWidget {
  MyDrawer();

  @override
  _MyDrawerState createState() => new _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  SignInContainer _signInContainer = new SignInContainer();

  _MyDrawerState();

  @override
  void initState() {
    super.initState();
    _signInContainer.listen((account) {
      if (this.mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext ctxt) {
    return new Drawer(
        child: new ListView(
      children: <Widget>[
        new DrawerHeader(
//              child: new Text("Alcohol Consumption Tracker", style: new TextStyle(color: Colors.white)),
          child: new Column(
            children: <Widget>[getTitle()],
          ),
//              child:  new GoogleUserCircleAvatar( identity: _currentUser,),
          decoration: new BoxDecoration(color: Colors.blue),
        ),
        new ListTile(
          title: new Text("Last 30 days"),
          onTap: () {
            Navigator.pop(ctxt);
            Navigator.push(
                ctxt,
                new MaterialPageRoute(
                    builder: (ctxt) =>
                        new ListProperties(title: "All properties")));
          },
        ),
        new ListTile(
          title: new Text("About"),
          onTap: () {
            {
              Navigator.pop(ctxt);
              AlertDialog dialog = new AlertDialog(
                  content: new RichText(
                      textAlign: TextAlign.justify,
                      text: new TextSpan(
                          text: "This app is for you if you want to buy "
                              "real estate for investment purposes and want "
                              "to to calculate rentability. For any "
                              "suggestions, feel free to contact me at ",
                          style: new TextStyle(
                              fontSize: 20.0, color: Colors.black),
                          children: [
                            new HyperLinkTextSpan(
                                text: "dev.sandor@gmail.com",
                                url:
                                    "mailto:dev.sandor@gmai.com?subject=About ProfitabilityCalculator",
                                style: new TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline)),
                            new TextSpan(text: ".")
                          ])));
              showDialog(context: ctxt, builder: (context) => dialog);
            }
          },
        )
      ],
    ));
  }

  Widget getTitle() {
    if (_signInContainer.getCurrentUser() == null) {
      return new ListTile(
        leading: getLead(),
        title: new Text("Sign in"),
        onTap: _signInContainer.handleSignIn,
      );
    }
    return new ListTile(
      leading: getLead(),
      title: new Text(_signInContainer.getCurrentUser().displayName),
      subtitle: new Text(_signInContainer.getCurrentUser().email),
      onTap: _signInContainer.handleSignOut,
    );
  }

  Widget getLead() {
    if (_signInContainer.getCurrentUser() == null) {
      return new CircleAvatar(child: new Text("?"));
    }
    return new GoogleUserCircleAvatar(
      identity: _signInContainer.getCurrentUser(),
    );
  }
}
