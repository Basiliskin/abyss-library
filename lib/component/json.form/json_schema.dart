import 'package:abbys/component/custom.text.field.dart';
import 'package:abbys/component/ensure.visible.when.focused.dart';
import 'package:abbys/service/common.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

enum JsonSchemaType {
  Input,
  Password,
  Email,
  TextArea,
  TextInput,
  Number,
  RadioButton,
  Switch,
  Checkbox,
  Select,
  Custom
}
const Map<String, JsonSchemaType> jsonSchemaTypes = {
  "Input": JsonSchemaType.Input,
  "Password": JsonSchemaType.Password,
  "Email": JsonSchemaType.Email,
  "TextArea": JsonSchemaType.TextArea,
  "TextInput": JsonSchemaType.TextInput,
  "RadioButton": JsonSchemaType.RadioButton,
  "Switch": JsonSchemaType.Switch,
  "Checkbox": JsonSchemaType.Checkbox,
  "Select": JsonSchemaType.Select,
  "Custom": JsonSchemaType.Custom,
  "Number": JsonSchemaType.Number
};

abstract class JsonSchemaItem {
  build(Map<String, dynamic> data);
}

class JsonSchemaItemText implements JsonSchemaItem {
  build(Map<String, dynamic> data) {}
}

class JsonSchema extends StatefulWidget {
  const JsonSchema(
      {@required this.formMap,
      @required this.onChanged,
      this.padding,
      this.errorMessages = const {},
      this.validations = const {},
      this.decorations = const {},
      this.buttonSave,
      this.buttonRemove,
      this.actionSave,
      this.buttonCancel,
      this.actionRemove});

  final Map errorMessages;
  final Map validations;
  final Map decorations;
  final Map formMap;
  final double padding;
  final Widget buttonSave;
  final Widget buttonCancel;
  final Widget buttonRemove;
  final Function actionSave;
  final Function actionRemove;
  final ValueChanged<Map> onChanged;

  @override
  _CoreFormState createState() => new _CoreFormState();
}

class _CoreFormState extends State<JsonSchema> {
  dynamic formGeneral;
  _init() {
    this.formGeneral = widget.formMap;
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void reassemble() {
    _init();
    super.reassemble();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.

    super.dispose();
  }

  String isRequired(item, value, errorMessages) {
    if (value.isEmpty) {
      return errorMessages[item['key']] ?? 'Please enter some text';
    }
    return null;
  }

  String validateEmail(item, String value) {
    String p = "[a-zA-Z0-9\+\.\_\%\-\+]{1,256}" +
        "\\@" +
        "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
        "(" +
        "\\." +
        "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
        ")+";
    RegExp regExp = new RegExp(p);

    if (regExp.hasMatch(value)) {
      return null;
    }
    return 'Email is not valid';
  }

  bool labelHidden(item) {
    if (item.containsKey('hiddenLabel')) {
      if (item['hiddenLabel'] is bool) {
        return !item['hiddenLabel'];
      }
    } else {
      return true;
    }
    return false;
  }

  _validator(item, value, itemType) {
    if (widget.validations.containsKey(item['key'])) {
      return widget.validations[item['key']](item, value);
    }
    if (item.containsKey('validator')) {
      if (item['validator'] != null) {
        if (item['validator'] is Function) {
          return item['validator'](item, value);
        }
      }
    }
    if (itemType == JsonSchemaType.Email) {
      return validateEmail(item, value);
    }

    if (item.containsKey('required')) {
      if (item['required'] == true ||
          item['required'] == 'True' ||
          item['required'] == 'true') {
        return isRequired(item, value, widget.errorMessages);
      }
    }

    return null;
  }

  _build(Map<String, dynamic> item) {
    final focusNode = safeGet(item, 'focusNode', null);
    final itemType = jsonSchemaTypes[item['type']];
    try {
      switch (itemType) {
        case JsonSchemaType.Custom:
          {
            try {
              Widget label = SizedBox.shrink();
              if (labelHidden(item)) {
                label = new Container(
                  child: new Text(
                    item['label'],
                    style: new TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                );
              }
              return Container(
                margin: new EdgeInsets.only(top: 5.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    label,
                    item['custom'](item, _validator, _handleChanged),
                  ],
                ),
              );
            } catch (e) {
              print(itemType);
              print(item);
              print(e);
            }
          }
          break;
        case JsonSchemaType.Number:
        case JsonSchemaType.Input:
        case JsonSchemaType.Password:
        case JsonSchemaType.Email:
        case JsonSchemaType.TextArea:
        case JsonSchemaType.TextInput:
          Widget label = SizedBox.shrink();
          if (labelHidden(item)) {
            label = new Container(
              child: new Text(
                item['label'],
                style:
                    new TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            );
          }
          //TODO : CustomTextField
          // TextFormField field;
          CustomTextField field;
          if (itemType == JsonSchemaType.Number) {
            field = CustomTextField(
              fieldType: itemType,
              copyButton: safeGet(item, 'copyButton', false),
              focusNode: focusNode,
              initialValue: "${item['value'] ?? 0}",
              readOnly: item.containsKey('readOnly') && item["readOnly"],
              decoration: item['decoration'] ??
                  widget.decorations[item['key']] ??
                  new InputDecoration(
                    hintText: item['placeholder'] ?? "",
                    helperText: item['helpText'] ?? "",
                  ),
              onChanged: (value) {
                item['value'] = int.parse(value ?? "0");
                _handleChanged(item);
              },
              validator: (value) {
                return _validator(item, value, itemType);
              },
              keyboardType: TextInputType.number,
            );
          } else {
            field = CustomTextField(
              fieldType: itemType,
              copyButton: safeGet(item, 'copyButton', false),
              readOnly: item.containsKey('readOnly') && item["readOnly"],
              initialValue: item['value'] ?? "",
              decoration: item['decoration'] ??
                  widget.decorations[item['key']] ??
                  new InputDecoration(
                    hintText: item['placeholder'] ?? "",
                    helperText: item['helpText'] ?? "",
                  ),
              maxLines: itemType == JsonSchemaType.TextArea ? 3 : 1,
              focusNode: focusNode,
              onChanged: (value) {
                item['value'] = value;
                _handleChanged(item);
              },
              obscureText: itemType == JsonSchemaType.Password,
              validator: (value) {
                return _validator(item, value, itemType);
              },
            );
          }

          return Container(
            margin: new EdgeInsets.only(top: 5.0),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                label,
                focusNode != null
                    ? EnsureVisibleWhenFocused(
                        focusNode: focusNode, child: field)
                    : field,
              ],
            ),
          );
        case JsonSchemaType.RadioButton:
          {
            List<Widget> radios = [];

            if (labelHidden(item)) {
              radios.add(new Text(item['label'],
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16.0)));
            }
            int radioValue = item['value'];
            for (var i = 0; i < item['items'].length; i++) {
              radios.add(
                new Row(
                  children: <Widget>[
                    new Expanded(child: new Text(item['items'][i]['label'])),
                    new Radio<int>(
                        value: item['items'][i]['value'],
                        groupValue: radioValue,
                        onChanged: (int value) {
                          item['value'] = value;
                          _handleChanged(item);
                        })
                  ],
                ),
              );
            }

            return Container(
              margin: new EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: radios,
              ),
            );
          }
        case JsonSchemaType.Switch:
          {
            bool flag = item.containsKey('value');
            if (flag) {
              flag = item['value'] ?? false;
            }
            return Container(
              margin: new EdgeInsets.only(top: 5.0),
              child: new Row(children: <Widget>[
                new Expanded(child: new Text(item['label'])),
                new Switch(
                  value: flag,
                  onChanged: (bool value) {
                    item['value'] = value;
                    _handleChanged(item);
                  },
                ),
              ]),
            );
          }
        case JsonSchemaType.Checkbox:
          {
            List<Widget> checkboxes = [];
            if (labelHidden(item)) {
              checkboxes.add(new Text(item['label'],
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16.0)));
            }
            for (var i = 0; i < item['items'].length; i++) {
              checkboxes.add(
                new Row(
                  children: <Widget>[
                    new Expanded(child: new Text(item['items'][i]['label'])),
                    new Checkbox(
                      value: item['items'][i]['value'],
                      onChanged: (bool value) {
                        item['items'][i]['value'] = value;
                        _handleChanged(item);
                      },
                    ),
                  ],
                ),
              );
            }

            return Container(
              margin: new EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: checkboxes,
              ),
            );
          }
        case JsonSchemaType.Select:
          {
            Widget label = SizedBox.shrink();
            if (labelHidden(item)) {
              label = new Text(item['label'],
                  style: new TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16.0));
            }
            final handleSelect = safeGet(item, 'handleChange', _handleChanged);
            return Container(
              margin: new EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  label,
                  new DropdownButton<String>(
                    hint: new Text(item['placeholder'] ?? "Select a user"),
                    value: "${item['value']}",
                    onChanged: (String newValue) {
                      item['value'] = newValue;
                      handleSelect(newValue);
                    },
                    items: item['items']
                        .map<DropdownMenuItem<String>>((dynamic data) {
                      return DropdownMenuItem<String>(
                        value: data['value'],
                        child: new Text(
                          data['label'],
                          style: new TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }
      }
    } catch (e) {
      print(e);
    }
  }

  List<Widget> jsonToForm() {
    List<Widget> listWidget = new List<Widget>();

    formGeneral = widget.formMap;
    if (safeGet(formGeneral, 'viewMode', false) == false &&
        widget.buttonCancel != null) {
      listWidget.add(new Container(
        margin: EdgeInsets.only(top: 10.0),
        child: InkWell(
          onTap: () {
            widget.actionSave(null);
          },
          child: widget.buttonCancel,
        ),
      ));
    }
    if (safeGet(formGeneral, 'title', null) != null) {
      listWidget.add(Text(
        formGeneral['title'],
        style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
      ));
    }
    if (safeGet(formGeneral, 'description', null) != null) {
      listWidget.add(Text(
        formGeneral['description'],
        style: new TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
      ));
    }

    if (widget.buttonRemove != null) {
      listWidget.add(new Container(
        margin: EdgeInsets.only(top: 10.0),
        child: InkWell(
          onTap: () {
            widget.actionRemove(formGeneral);
          },
          child: widget.buttonRemove,
        ),
      ));
    } else if (widget.buttonSave != null) {
      listWidget.add(new Container(
        margin: EdgeInsets.only(top: 10.0),
        child: InkWell(
          onTap: () {
            if (_formKey.currentState.validate()) {
              widget.actionSave(formGeneral);
            }
          },
          child: widget.buttonSave,
        ),
      ));
    }
    final fields = safeGet(formGeneral, 'fields', []);
    for (var count = 0; count < fields.length; count++) {
      Map item = fields[count];

      if (jsonSchemaTypes.containsKey(safeGet(item, 'type', '-')))
        listWidget.add(_build(item));
      else
        print("not supported type = ${safeGet(item, 'type', '-')}");
    }

    if (widget.buttonSave != null) {
      listWidget.add(new Container(
        margin: EdgeInsets.only(top: 10.0),
        child: InkWell(
          onTap: () {
            if (_formKey.currentState.validate()) {
              widget.actionSave(formGeneral);
            }
          },
          child: widget.buttonSave,
        ),
      ));
    }
    return listWidget;
  }

  void _handleChanged(item) {
    setState(() {
      widget.onChanged({"form": formGeneral, "item": item});
    });
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidate: safeGet(formGeneral, 'autoValidated', false),
      key: _formKey,
      child: new Container(
        padding: new EdgeInsets.all(widget.padding ?? 8.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: jsonToForm(),
        ),
      ),
    );
  }
}
