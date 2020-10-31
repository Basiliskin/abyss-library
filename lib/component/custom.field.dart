import 'dart:convert';

import 'package:abbys/component/json.form.dart';
import 'package:abbys/service/common.dart';
import 'package:flutter/material.dart';

/*
TODO:
  - new item
  - new label
  - filter not working
  - 2)remove all labeled items
  - 1)remove not working


  Input - edit/copy
  Link - show/edit/copy
  File/s - name/date/download/upload/remove  
*/
class CustomFormField extends StatefulWidget {
  final Map item;
  final Function _handleChanged;
  final Function updateField;
  final int index;
  CustomFormField(this.item, this.index, this._handleChanged, this.updateField);
  @override
  _CustomFormFieldState createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  String _fieldType = "Input";
  dynamic _fieldValue = "";
  int _id;
  FocusNode _focusNode;
  _load() {
    try {
      dynamic value = safeGet(widget.item, "value", {});
      Map jsonValue = value is String ? json.decode(value) : value;
      _fieldType = safeGet(jsonValue, "type", "Input");
      dynamic tmp = safeGet(jsonValue, "value", "");
      _id = safeGet(jsonValue, "id", 0);
      if (tmp is Map) {
        _id = safeGet(tmp, "id", 0);
        _fieldType = safeGet(tmp, "type", "Input");
        _fieldValue = safeGet(tmp, "value", "");
      } else
        _fieldValue = tmp is String ? tmp : json.encode(tmp);
      _focusNode = FocusNode();
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    _load();
    super.initState();
  }

  @override
  void reassemble() {
    _load();
    super.reassemble();
  }

  @override
  void dispose() {
    if (_focusNode != null) _focusNode.dispose();

    super.dispose();
  }

  _actionSave(response) {
    final List fields = response["fields"];
    Map d = {"id": _id};
    fields.forEach((element) {
      dynamic key = element["key"];
      dynamic value = element["value"];
      d[key] = value;
    });
    return d;
  }

  _actionRemove(response) {}
  _changeType(value) {
    setState(() => {
          _fieldType = value,
          _formChange(null),
          Future.delayed(Duration(milliseconds: 300), () {
            if (_focusNode != null) _focusNode.requestFocus();
          })
        });
  }

  Widget _content(BuildContext context) {
    final fieldType = {
      'key': 'type',
      'label': 'Type',
      'hiddenLabel': true,
      'placeholder': 'Select Type',
      'items': [
        {'value': 'Input', 'label': 'Input'},
        {'value': 'Password', 'label': 'Password'},
        {'value': 'Email', 'label': 'Email'},
        {'value': 'TextArea', 'label': 'TextArea'},
        {'value': 'TextInput', 'label': 'TextInput'},
        {'value': 'Number', 'label': 'Number'},
        //{'value': 'Delete', 'label': 'Delete'}
      ],
      'type': 'Select',
      'value': _fieldType,
      'handleChange': (selectedType) => {_changeType(selectedType)}
    };
    List<Map<String, dynamic>> fields = [fieldType];
    Map<String, dynamic> props = {
      'key': 'value',
      'label': _fieldType,
      'hiddenLabel': true,
      'type': _fieldType,
      'value': _fieldValue,
      'focusNode': _focusNode
    };
    props['copyButton'] = true;
    fields.add(props);

    final Map formData = {
      "formDecoration": {
        'name': InputDecoration(
            prefixIcon: Icon(Icons.info), border: OutlineInputBorder()),
      },
      "formData": {'viewMode': true, 'autoValidated': false, 'fields': fields}
    };
    return JsonForm(formData, _actionSave, _actionRemove, _formChange);
  }

  _formChange(form) {
    if (form != null) {
      dynamic item = form["item"];
      _fieldValue = item["value"];
    }
    Map<String, dynamic> vars = {
      "id": _id,
      "type": _fieldType,
      "value": _fieldValue
    };
    widget.item["value"] = vars;
    widget.updateField(widget.index, vars);
    widget._handleChanged(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Stack(children: <Widget>[
      SafeArea(child: Column(children: <Widget>[_content(context)]))
    ]));
  }
}
