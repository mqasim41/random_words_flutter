import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var favorites = <WordPair>[];

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
  
  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
  
  // Add a method to remove a specific favorite item
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
  
  // Add a method to remove multiple favorites at once
  void removeMultipleFavorites(List<WordPair> pairs) {
    favorites.removeWhere((pair) => pairs.contains(pair));
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0; 
  
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage(
          onNavigateBack: () {
            // Navigate back to Home page after confirmation
            setState(() {
              selectedIndex = 0;
            });
          },
        );
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(pair.asLowerCase, style: style),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  final Function()? onNavigateBack;

  const FavoritesPage({
    Key? key,
    this.onNavigateBack,
  }) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Set to track selected items for batch deletion
  final Set<WordPair> _selectedItems = {};

  // Show confirmation dialog for single item
  Future<bool> _showSingleItemDeleteConfirmationDialog(WordPair pair) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text('Are you sure you want to remove "${pair.asLowerCase}" from favorites?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false for "No"
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true for "Yes"
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
    
    // Default to false if the dialog was somehow dismissed without a selection
    return result ?? false;
  }

  // Show confirmation dialog for deleting multiple items
  Future<bool> _showMultiDeleteConfirmationDialog(List<WordPair> items) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${items.length} selected item(s)?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return false for "No"
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Return true for "Yes"
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
    
    // Default to false if the dialog was somehow dismissed without a selection
    return result ?? false;
  }

  // Method to handle deletion of selected items
  void _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) {
      // Show snackbar if no items are selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No Item Selected'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show confirmation dialog
    bool confirmed = await _showMultiDeleteConfirmationDialog(_selectedItems.toList());
    
    if (confirmed) {
      // Remove selected items from favorites
      Provider.of<MyAppState>(context, listen: false)
          .removeMultipleFavorites(_selectedItems.toList());
      
      // Clear selection
      setState(() {
        _selectedItems.clear();
      });
      
      // Navigate back
      if (widget.onNavigateBack != null) {
        widget.onNavigateBack!();
      }
    }
  }

  // Method to handle single item tap deletion
  void _handleItemTap(WordPair pair) async {
    // Show confirmation dialog
    bool confirmed = await _showSingleItemDeleteConfirmationDialog(pair);
    
    if (confirmed) {
      // Remove from favorites
      Provider.of<MyAppState>(context, listen: false).removeFavorite(pair);
      
      // Navigate back to Generator page
      if (widget.onNavigateBack != null) {
        widget.onNavigateBack!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Suggestions'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteSelectedItems,
            tooltip: 'Delete selected',
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('You have ${appState.favorites.length} favorites:'),
          ),
          for (var pair in appState.favorites)
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text(pair.asLowerCase),
              // Add checkbox for selection instead of checkmark icon
              trailing: Checkbox(
                value: _selectedItems.contains(pair),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedItems.add(pair);
                    } else {
                      _selectedItems.remove(pair);
                    }
                  });
                },
              ),
              // Tapping the item triggers the single-item deletion dialog
              onTap: () => _handleItemTap(pair),
            ),
        ],
      ),
    );
  }
}