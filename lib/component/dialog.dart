import 'dart:math';

import 'package:abbys/component/list.item.dart';
import 'package:abbys/component/wave.progress.dart';
import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:flutter/material.dart';
import 'package:abbys/component/form.dart';

class DialogComponent extends StatefulWidget {
  final DbService service;
  final List<ListIntValue> labels;
  final Map item;
  final Function onSaveItem;
  DialogComponent(
      {Key key, this.item, this.onSaveItem, this.labels, this.service})
      : super(key: key);
  @override
  _DialogComponentState createState() => _DialogComponentState(item);
}

class _DialogComponentState extends State<DialogComponent> {
  final Map data;
  bool _loading = false;
  _DialogComponentState(this.data);

  _addField() {
    Random _rnd = Random();
    setState(() {
      if (data.containsKey('custom') == false) {
        data['custom'] = [];
      }
      data['custom']
          .add({"value": "", "type": "Input", "id": _rnd.nextInt(1000000)});
    });
  }

  _removeField(_id) {
    setState(() {
      data['custom'] = data['custom']
          .where((element) => element["value"]['id'] != _id)
          .toList();
    });
  }

  _isLoading(bool loading) {
    setState(() {
      _loading = loading;
    });
  }

  _actionSave(Map data, bool closeAfterSaved) {
    setState(() {
      if (data != null) widget.onSaveItem(data);
      if (closeAfterSaved)
        Navigator.of(context, rootNavigator: true).pop('dialog');
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> item = [];
    item.add(SingleChildScrollView(
        padding: const EdgeInsets.all(0.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ItemFormController(
              data: data,
              onSave: _actionSave,
              labels: widget.labels,
              addField: _addField,
              service: widget.service,
              isLoading: _isLoading,
              removeField: _removeField)
        ])));
    if (_loading) {
      item.add(Opacity(
        opacity: 0.1,
        //ModalBarried used to make a modal effect on screen
        child: ModalBarrier(
          dismissible: false,
          color: Colors.black54,
        ),
      ));
      item.add(Center(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          WaveProgress(180.0, PROGRESSBAR_COLOR, PROGRESSBAR_COLOR, 40.0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text("Updating"),
          )
        ],
      )));
    }
    return Stack(children: item);
  }
}
