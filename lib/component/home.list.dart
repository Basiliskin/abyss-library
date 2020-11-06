import 'package:abbys/component/list.item.dart';
import 'package:flutter/material.dart';

class HomeList extends StatefulWidget {
  final Stream<List<Map>> stream;
  final List<Map> mapList;
  final Function removeItem;
  final Function editItem;
  final Function onSeachByLabel;
  final Function onSetFavorite;
  HomeList(this.mapList, this.removeItem, this.editItem, this.onSeachByLabel,
      this.stream, this.onSetFavorite);

  @override
  _HomeListState createState() => _HomeListState();
  _search(value) {
    print(value);
    onSeachByLabel(value);
  }
}

class _HomeListState extends State<HomeList> {
  List<ListItem> items = [];

  _load(List<Map> newData) {
    items.clear();
    (newData ?? widget.mapList).forEach((data) =>
        {items.add(ListItemData(data, widget._search, widget.onSetFavorite))});
  }

  @override
  void initState() {
    super.initState();
    _load(widget.mapList);
    widget.stream.asBroadcastStream().listen((List<Map> newData) {
      setState(() {
        _load(newData);
      });
    });
  }

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final itemData = item.itemData();
            String itemKey = itemData["itemId"];
            final itemControl = Expanded(child: item.buildItem(context));
            final control = Row(children: [itemControl]);
            final component = Dismissible(
                key: Key(itemKey),
                onDismissed: (direction) {
                  widget.removeItem(itemData);
                },
                child: Flex(
                  direction: Axis.vertical,
                  children: [control],
                ));
            return InkWell(
                //behavior: HitTestBehavior.translucent,
                onTap: () => {widget.editItem(itemData)},
                child: component);
          }),
    );
  }
}
