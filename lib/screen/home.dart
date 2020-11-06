import 'dart:async';
import 'dart:convert';
import 'package:abbys/component/dialog.dart';
import 'package:abbys/component/fab.circular.menu.dart';
import 'package:abbys/component/home.list.dart';
import 'package:abbys/component/list.item.dart';
import 'package:abbys/component/loading.dialog.dart';
import 'package:abbys/component/nav.drawer.dart';
import 'package:abbys/service/common.dart';
import 'package:abbys/service/db.dart';
import 'package:abbys/service/route.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class HomeScreen extends StatefulWidget {
  final DbService service;
  HomeScreen(this.service);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  TextEditingController _searchQueryController = TextEditingController();
  bool _isSearching = false;
  bool _loading = false;
  String searchQuery = "Search query";
  List<ListIntValue> labels = [];
  bool _loaded = false;
  ListFilter _filter = new ListFilter("", "");
  List<Map> mapList;
  StreamController<List<Map>> _controller = BehaviorSubject();
  StreamController<List<ListIntValue>> _controllerLabel = BehaviorSubject();

  Sink<List<Map>> get sinkItems => _controller.sink;
  Sink<List<ListIntValue>> get sinkLabels => _controllerLabel.sink;

  _sortItems(a, b) {
    final isFavoriteA = safeGet(a, 'isFavorite', false);
    final isFavoriteB = safeGet(b, 'isFavorite', false);
    if (isFavoriteA != isFavoriteB)
      return isFavoriteA ? -1 : isFavoriteB ? 1 : 0;

    int timeA = safeGet(a, 'time', 0);
    int timeB = safeGet(b, 'time', 0);
    return timeB - timeA;
  }

  List<Map> _filteredData() {
    List<Map> res =
        mapList.where((element) => _filter.filtered(element)).toList();
    Map<String, int> dic = {};

    res.forEach((element) {
      _filter.mapLabels(element, dic);
    });
    final labels =
        dic.entries.map((e) => ListIntValue(e.key, e.value)).toList();
    labels.sort((a, b) => a.name.compareTo(b.name));
    res.sort((a, b) => _sortItems(a, b));
    sinkLabels.add(labels);
    sinkItems.add(res);
    this.labels = labels;
    return res;
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    changeNotifier.close();
    _controller.close();
    _controllerLabel.close();
    super.dispose();
    _controller = BehaviorSubject();
    _controllerLabel = BehaviorSubject();
  }

  final changeNotifier = new StreamController.broadcast();
  Future _saveCollection([bool renew = false]) {
    setState(() {
      _loading = true;
    });
    return new Future.delayed(
        const Duration(milliseconds: 300),
        () async => {
              if (renew)
                await widget.service.renew({"items": mapList})
              else
                await widget.service.save({"items": mapList}),
              setState(() {
                _loading = false;
              })
            });
  }

  @override
  void initState() {
    _loaded = false;
    super.initState();
  }

  @override
  void reassemble() {
    _loaded = false;
    super.reassemble();
  }

  _onSaveItem(Map newData) {
    final valid = "itemId,title,label,href,description,custom,image,isFavorite"
        .split(',');
    Map ndata = {};
    newData.forEach((key, value) {
      if (valid.indexOf(key) >= 0) ndata[key] = value;
    });

    final itemId = ndata["itemId"];
    int current = mapList
        .indexWhere((element) => safeGet(element, "itemId", "") == itemId);
    ndata["itemId"] = itemId;
    ndata["time"] = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      if (current < 0) {
        mapList.add(ndata);
      } else {
        mapList[current] = ndata;
      }
      _filteredData();
    });
  }

  _showDialog(BuildContext context, Map item) {
    // show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
            content: DialogComponent(
                item: item,
                onSaveItem: _onSaveItem,
                service: widget.service,
                labels: labels));
      },
    );
  }

  void _startSearch() {
    ModalRoute.of(context)
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      _isSearching = true;
    });
  }

  _searchByLabelName(String labelName) {
    setState(() {
      _filter = ListFilter("", labelName);
      _filteredData();
    });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      _filter = ListFilter(newQuery, "");
      _filteredData();
    });
  }

  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _isSearching = false;
      _searchQueryController.clear();
      updateSearchQuery("");
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "search...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.black),
      ),
      style: TextStyle(color: Colors.black, fontSize: 16.0),
      onChanged: (query) => updateSearchQuery(query),
      onSubmitted: (value) => {
        setState(() {
          _isSearching = false;
        })
      },
    );
  }

  _buildActions(List<Widget> filterComponent) {
    final data = {
      "id": getRandomString(16),
      "title": "",
      "description": "",
      "href": "",
      "label": []
    };
    data["itemId"] = generateMd5(json.encode(data));
    if (_isSearching) {
      filterComponent.add(IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          if (_searchQueryController == null ||
              _searchQueryController.text.isEmpty) {
            Navigator.pop(context);
            return;
          }
          _clearSearchQuery();
        },
      ));
    } else {
      filterComponent.add(IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ));
      filterComponent.add(IconButton(
        icon: const Icon(Icons.folder_open),
        onPressed: () => _drawerKey.currentState.openDrawer(),
      ));
      filterComponent.add(IconButton(
        icon: const Icon(Icons.add),
        onPressed: () => {_showDialog(context, data)},
      ));
      if (!_filter.isEmpty())
        filterComponent.add(IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _clearSearchQuery(),
        ));
    }
  }

  _homeListRemoveItem(Map itemData) {
    final itemId = itemData["itemId"];
    int current = mapList
        .indexWhere((element) => safeGet(element, "itemId", "") == itemId);
    if (current >= 0) {
      setState(() {
        mapList.removeAt(current);
        _filteredData();
      });
    }
  }

  _homeSetFavorite(Map itemData) {
    itemData['isFavorite'] = !safeGet(itemData, 'isFavorite', false);
    _onSaveItem(itemData);
  }

  buildContent(BuildContext context, BoxConstraints viewportConstraints) {
    final Map<String, dynamic> screenData = {"title": "Abyss Library  "};
    final String title = screenData["title"];
    final editItem = (Map data) => _showDialog(context, data);
    List<Widget> widgetList = new List<Widget>();
    widgetList.add(HomeList(mapList, _homeListRemoveItem, editItem,
        _searchByLabelName, _controller.stream, _homeSetFavorite));

    final ModalRoundedProgressBar progressBar = ModalRoundedProgressBar(
        textMessage: screenData["loading"] ?? "Loading");

    List<Widget> filterComponent = <Widget>[];
    _buildActions(filterComponent);
    final double transformMenu = -8.0;
    List<Widget> menuItems = <Widget>[];
    menuItems.add(IconButton(
        icon: Icon(Icons.save),
        onPressed: () {
          _saveCollection();
          changeNotifier.sink.add(null);
        }));
    menuItems.add(IconButton(
        icon: Icon(Icons.update),
        onPressed: () {
          _saveCollection(true);
          changeNotifier.sink.add(null);
        }));
    FabCircularMenu menu = menuItems.length > 0
        ? FabCircularMenu(
            ringColor: MENU_COLOR,
            shouldTriggerChange: changeNotifier.stream,
            ringDiameter: 200,
            transform: Matrix4.translationValues(-transformMenu, 0.0, 0.0),
            alignment: Alignment.bottomRight,
            children: menuItems)
        : null;

    final scaffold = Scaffold(
        key: _drawerKey, // assign key to Scaffold
        drawer: NavDrawerComponent(
            title, labels, _searchByLabelName, _controllerLabel.stream),
        appBar: AppBar(
            leading: screenData["filter"] == false && _isSearching == false
                ? IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Keys.navKey.currentState
                          .pushReplacementNamed(Routes.homeScreen);
                    })
                : Container(),
            title: _isSearching ? _buildSearchField() : null,
            actions: filterComponent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widgetList,
          ),
        ),
        floatingActionButton: menu);
    List<Widget> stackItems = [];
    stackItems.add(scaffold);
    if (_loading) stackItems.add(progressBar);
    return Stack(
      children: stackItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mapList == null) {
      final Map<String, dynamic> arguments =
          ModalRoute.of(context).settings.arguments;
      if (!_loaded && arguments.containsKey("items")) {
        _loaded = true;
        List loadedItems = arguments["items"];
        mapList = [];
        loadedItems.forEach((data) => {
              data["itemId"] = generateMd5(json.encode(data)),
              mapList.add(Map.from(data))
            });
      }
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: buildContent(context, viewportConstraints),
            ),
          ),
        );
      },
    );
  }
}
