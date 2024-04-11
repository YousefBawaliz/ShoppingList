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

  late Future<List<GroceryItem>> _loadedItems;
  String? error;

  @override
  void initState() {
    _loadedItems = _LoadItems();
    super.initState();
  }

  Future<List<GroceryItem>> _LoadItems() async {
    final url = Uri.https(
        'flutter-prep-6fefd-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');

    // try {
    final response = await http.get(url);
    //statusCode 400/500 is erroe
    if (response.statusCode > 400) {
      throw Exception("failed to fetch gricery items");
    }
    print(response.body);

    //to check if response is null (i.e no items in the backend)
    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = jsonDecode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      //we're going through the entried in categories from categories.dart, and we're taking a look at those items,
      //and for every item we check if the value(Category object) has a name that is equal to the value stored in
      // the category key of the item that is part of the response:
      final category = categories.entries
          .firstWhere((element) => element.value.name == item.value['category'])
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
    return loadedItems;
    // setState(
    //   () {
    //     _groceryItems = loadedItems;
    //     _isLoading = false;
    //   },
    // );

    // } catch (e) {
    //   print("error");
    // }
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
        body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(snapshot.error
                    .toString()), //gives us access to the error code at the top
              );
            }

            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No items yet'),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) => Dismissible(
                key: ValueKey(snapshot.data![index].id),
                onDismissed: (direction) => _removeItem(_groceryItems[index]),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: snapshot.data![index].category.color,
                  ),
                  trailing: Text(snapshot.data![index].quantity.toString()),
                ),
              ),
            );
          },
        ));
  }
}
