import 'dart:convert';

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
// import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? error;

  //adding items using navigator.pop/push
  // void _additem() async {
  //   final _newItem = await Navigator.of(context).push<GroceryItem>(
  //     MaterialPageRoute(
  //       builder: (context) => NewItem(),
  //     ),
  //   );
  //   if (_newItem == null) {
  //     return;
  //   }
  //   setState(() {
  //     _groceryItems.add(_newItem);
  //   });
  // }

  @override
  void initState() {
    _LoadItems();
    super.initState();
  }

  void _LoadItems() async {
    final url = Uri.https(
        'flutter-prep-6fefd-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    try {
      final response = await http.get(url);
      //statusCode 400/500 is erroe
      if (response.statusCode > 400) {
        setState(() {
          error = 'Failed to fetch data  pls try again later';
        });
      }
      print(response.body);

      //to check if response is null (i.e no items in the backend)
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = jsonDecode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        //we're going through the entried in categories from categories.dart, and we're taking a look at those items,
        //and for every item we check if the value(Category object) has a name that is equal to the value stored in
        // the category key of the item that is part of the response:
        final category = categories.entries
            .firstWhere(
                (element) => element.value.name == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            category: category,
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
          ),
        );
      }
      setState(
        () {
          _groceryItems = loadedItems;
          _isLoading = false;
        },
      );
    } catch (e) {
      print("error");
    }
  }

  //adding items using database
  //should still be async, since we are only adding items after returning from NewItem screen
  void _additem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    } else {
      setState(() {
        _groceryItems.add(newItem);
      });
    }

    //to load the items once we enter the screen for the first time after we navigate back from NewItem()
    //this is redundent though, since this is the 2nd request of the same data in this screen, so it's better to
    //get the data back from NewItem Screen where the request already happened.

    // _LoadItems();
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
        'flutter-prep-6fefd-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items yet'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) => _removeItem(_groceryItems[index]),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }

    if (error != null) {
      Widget content = Center(
        child: Text(error!),
      );
    }

    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: _additem,
              icon: Icon(Icons.add),
            )
          ],
          title: Text("Your Groceries"),
        ),
        body: content);
  }
}
