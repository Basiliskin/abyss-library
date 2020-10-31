import 'package:abbys/component/list.item.dart';
import 'package:flutter/material.dart';

class NavDrawerComponent extends StatefulWidget {
  final Stream<List<ListIntValue>> stream;
  final String title;
  final List<ListIntValue> labels;
  final Function(String) updateSearch;
  NavDrawerComponent(this.title, this.labels, this.updateSearch, this.stream);
  @override
  _NavDrawerComponentState createState() => _NavDrawerComponentState();
}

class _NavDrawerComponentState extends State<NavDrawerComponent> {
  List<ListIntValue> items = [];

  _load(List<ListIntValue> newData) {
    items = newData;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load(widget.labels);
    widget.stream.asBroadcastStream().listen((List<ListIntValue> newData) {
      setState(() {
        _load(newData);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return new GestureDetector(
              onTap: () => {print(item)},
              child: ListTile(
                leading: Icon(Icons.input),
                title: Text(item.title),
                onTap: () => {widget.updateSearch(item.name)},
              ));
        });
    return Drawer(child: list);
  }
}
