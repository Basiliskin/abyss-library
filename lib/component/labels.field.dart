import 'package:abbys/component/autocomplete.dart';
import 'package:abbys/component/badge/src/badge.dart';
import 'package:abbys/component/badge/src/badge_shape.dart';
import 'package:abbys/component/list.item.dart';
import 'package:abbys/service/common.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LabelFieldController extends StatefulWidget {
  final Map item;
  final Function _handleChanged;
  final List<ListIntValue> labels;
  LabelFieldController(this.item, this._handleChanged, this.labels);
  @override
  _LabelFieldControllerState createState() => _LabelFieldControllerState();
  updateItem(value) {
    item["value"] = new List<String>.from(value);
    _handleChanged(item);
  }
}

class _LabelFieldControllerState extends State<LabelFieldController> {
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
  String labelName = "";
  List _labels = [];
  TextEditingController editingController = TextEditingController();
  @override
  void initState() {
    List labels = safeGet(widget.item, "value", []);
    _labels = new List<String>.from(labels);
    super.initState();
  }

  @override
  void reassemble() {
    List labels = safeGet(widget.item, "value", []);
    _labels = new List<String>.from(labels);
    super.reassemble();
  }

  _addLabel(String labelName) {
    setState(() {
      _labels = _labels
          .where((label) =>
              labelName.toLowerCase().compareTo(label.toLowerCase()) != 0)
          .toList()
            ..add(labelName);
      widget.updateItem(_labels);
    });
  }

  _removeLabel(String labelName) {
    setState(() {
      _labels = _labels
          .where((label) =>
              labelName.toLowerCase().compareTo(label.toLowerCase()) != 0)
          .toList();
      widget.updateItem(_labels);
    });
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _labels.length,
                    itemBuilder: (context, index) {
                      final badge = Badge(
                          badgeColor: index % 2 != 0
                              ? LABEL_ODD_COLOR
                              : LABEL_EVEN_COLOR,
                          shape: BadgeShape.square,
                          borderRadius: 10,
                          toAnimate: false,
                          badgeContent: Text(
                              toBeginningOfSentenceCase(_labels[index]),
                              style: TextStyle(color: Colors.black)));

                      return Row(children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(left: 5.0, right: 5.0)),
                        GestureDetector(
                            onTap: () => {_removeLabel(_labels[index])},
                            child: badge)
                      ]);
                    })),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.labels.map((element) => element.name).toList();
    return SingleChildScrollView(
        child: SafeArea(
            child: Column(children: <Widget>[
      SimpleAutoCompleteTextField(
        key: key,
        decoration: new InputDecoration(errorText: "Label"),
        controller:
            editingController, //TextEditingController(text: "Starting Text"),
        suggestions: suggestions,
        clearOnSubmit: true,
        textSubmitted: (text) => setState(() {
          if (text != null && text.isNotEmpty) _addLabel(text);
          editingController.text = "";
        }),
      ),
      Padding(padding: const EdgeInsets.symmetric(vertical: 5.0)),
      Container(width: 320, height: 80, child: _content(context))
    ])));
  }
}
