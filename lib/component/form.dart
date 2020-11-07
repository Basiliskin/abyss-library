import 'package:abbys/component/custom.field.dart';
import 'package:abbys/component/image.field.dart';
import 'package:abbys/component/json.form.dart';
import 'package:abbys/component/labels.field.dart';
import 'package:abbys/component/list.item.dart';
import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:flutter/material.dart';

class ItemFormController extends StatefulWidget {
  final DbService service;
  final List<ListIntValue> labels;
  final Function onSave;
  final Function addField;
  final Function removeField;
  final Map data;
  final Function(bool) isLoading;
  ItemFormController(
      {Key key,
      this.data,
      this.onSave,
      this.labels,
      this.addField,
      this.service,
      this.isLoading,
      this.removeField})
      : super(key: key);
  @override
  _ItemFormControllerState createState() => _ItemFormControllerState();
}

class _ItemFormControllerState extends State<ItemFormController> {
  _actionSave(response, [closeAfterSaved = true]) {
    if (response != null) {
      final List fields = response["fields"];
      Map d = {"itemId": widget.data["itemId"]};
      fields.forEach((element) {
        String key = element["key"];
        dynamic value = element["value"];
        if (key.startsWith("custom") == true) {
          if (!d.containsKey("custom")) d["custom"] = [];
          d["custom"].add(value);
        } else {
          d[key] = value;
        }
      });
      //print(prettyJson(d));
      widget.onSave(d, closeAfterSaved);
    } else {
      widget.onSave(null, closeAfterSaved);
    }
  }

  _actionRemove(response) {}

  _updateCustomField(index, value) {
    print(value);
    widget.data['custom'][index]["value"] = value;
  }

  Widget buildDesc(BuildContext context) {
    final data = widget.data;
    final fields = [
      {
        'key': 'title',
        'type': 'Input',
        'label': 'Title',
        'placeholder': "Enter Name",
        'required': true,
        'hiddenLabel': true,
        'value': safeGet(data, "title", "")
      },
      {
        'key': 'label',
        'type': 'Custom',
        'label': 'Label',
        'hiddenLabel': true,
        'required': false,
        'value': safeGet(data, "label", []),
        'custom': (item, _validator, _handleChanged) =>
            LabelFieldController(item, _handleChanged, widget.labels)
      },
      {
        'key': 'href',
        'type': 'Input',
        'label': 'href',
        'placeholder': "Enter URL",
        'required': false,
        'hiddenLabel': true,
        'value': safeGet(data, "href", "")
      },
      {
        'key': 'description',
        'type': 'TextArea',
        'label': 'Description',
        'placeholder': "Description",
        'required': false,
        'hiddenLabel': true,
        'value': safeGet(data, "description", "")
      }
    ];

    if (data.containsKey('custom')) {
      data['custom'].asMap().forEach((index, value) => {
            fields.add({
              'key': 'custom$index',
              'type': 'Custom',
              'hiddenLabel': true,
              'required': false,
              'value': value,
              'custom': (item, _validator, _handleChanged) => CustomFormField(
                  item, index, _handleChanged, _updateCustomField)
            })
          });
    }

    fields.add({
      'key': 'image',
      'type': 'Custom',
      'label': 'Image',
      'hiddenLabel': true,
      'value': safeGet(data, "image", []),
      'custom': (item, _validator, _handleChanged) =>
          ImageField(item, widget.service, _handleChanged, widget.isLoading)
    });
    fields.add({
      'key': 'btn0',
      'type': 'Custom',
      'label': 'Description',
      'hiddenLabel': true,
      'value': 1,
      'custom': (item, _validator, _handleChanged) => Container(
            margin: EdgeInsets.only(top: 10.0),
            child: InkWell(
              onTap: () {
                widget.addField();
              },
              child: Container(
                height: 40.0,
                color: BUTTON_COLOR,
                child: Center(
                  child: Text("Add Field",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          )
    });

    final Map formData = {
      "formDecoration": {
        'name': InputDecoration(
            prefixIcon: Icon(Icons.info), border: OutlineInputBorder()),
      },
      "formData": {'autoValidated': false, 'fields': fields}
    };

    return JsonForm(formData, _actionSave, _actionRemove, _formChange);
  }

  _formChange(form) {
    final response = safeGet(form, "form", null);
    if (response != null) _actionSave(response, false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SafeArea(child: Column(children: <Widget>[buildDesc(context)])));
  }
}
