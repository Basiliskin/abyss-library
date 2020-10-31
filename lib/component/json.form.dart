import 'package:abbys/service/common.dart';
import 'package:flutter/material.dart';

import 'json.form/json_schema.dart';

//https://raw.githubusercontent.com/VictorRancesCode/json_to_form/master/lib/json_to_form.dart
class JsonForm extends StatefulWidget {
  final Map formData;
  final Function actionSave;
  final Function actionRemove;
  final Function formChange;
  JsonForm(this.formData, this.actionSave, this.actionRemove, this.formChange,
      {Key key})
      : super(key: key);
  @override
  _JsonFormState createState() => _JsonFormState();
}

class _JsonFormState extends State<JsonForm> {
  dynamic response;
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (widget.formData["title"] != null) {
      children.add(new Container(
        child: new Text(
          widget.formData["title"] ?? "Settings",
          style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
        ),
        margin: EdgeInsets.only(top: 10.0),
      ));
    }
    final viewMode =
        safeGet(widget.formData, "formData.viewMode", false) == true;
    children.add(new JsonSchema(
      decorations: safeGet(widget.formData, "formDecoration", null),
      formMap: safeGet(widget.formData, "formData", {}),
      onChanged: (dynamic response) {
        this.response = response;
        widget.formChange(response);
      },
      actionSave: widget.actionSave,
      actionRemove: widget.actionRemove,
      buttonCancel: viewMode
          ? null
          : Container(
              height: 40.0,
              color: BUTTON_COLOR,
              child: Center(
                child: Text("Close",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
    ));
    return new SingleChildScrollView(
        child: new Center(child: new Column(children: children)));
  }
}
