import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:abbys/service/route.dart';
import 'package:flutter/material.dart';

class PasswordScreen extends StatefulWidget {
  final DbService service;
  PasswordScreen(this.service);
  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final myController = TextEditingController();
  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    myController.dispose();
    super.dispose();
  }

  //Create handle password
  bool _obscureText = true;
  _content() {
    return Container(
      padding: EdgeInsets.only(top: 60, left: 20, right: 20),
      child: Column(
        children: <Widget>[
          CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset("assets/image/logo.png"))),
          SizedBox(
            height: 40,
          ),
          TextField(
            autofocus: true,
            controller: myController,
            obscureText: _obscureText,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                hintText: "Password",
                labelText: "Password",
                prefixIcon: IconButton(
                  icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      myController.text = "";
                    });
                  },
                )),
          ),
          SizedBox(
            height: 40,
          ),
          SizedBox(
              height: 60,
              width: 180,
              child: RaisedButton(
                child: Text("Enter"),
                onPressed: () {
                  widget.service.setUserPassword(myController.text);
                  Navigator.pushReplacementNamed(context, Routes.startScreen);
                },
                color: BUTTON_COLOR,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(child: _content())));
    }));
  }
}
