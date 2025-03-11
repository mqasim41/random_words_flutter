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
  var selectedFavorites = <WordPair>{}; // New: For tracking selected items in favorites

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

  // New: Remove a specific word pair from favorites
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    selectedFavorites.remove(pair); // Also remove from selected list if present
    notifyListeners();
  }

  // New: Toggle selection state for a word pair
  void toggleSelection(WordPair pair) {
    if (selectedFavorites.contains(pair)) {
      selectedFavorites.remove(pair);
    } else {
      selectedFavorites.add(pair);
    }
    notifyListeners();
  }

  // New: Remove multiple selected favorites
  void removeSelectedFavorites() {
    favorites.removeWhere((pair) => selectedFavorites.contains(pair));
    selectedFavorites.clear();
    notifyListeners();
  }

  // New: Clear all selections
  void clearSelections() {
    selectedFavorites.clear();
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
        page = FavoritesPage();
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

class FavoritesPage extends StatelessWidget {
  // Lab Task 1: Show confirmation dialog for deletion
  void _showDeleteConfirmationDialog(BuildContext context, WordPair pair) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Suggestion'),
          content: Text('Are you sure you want to delete "${pair.asLowerCase}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                // Get the app state and remove the pair
                final appState = Provider.of<MyAppState>(context, listen: false);
                appState.removeFavorite(pair);
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Lab Task 2: Show confirmation dialog for multiple deletion
  void _showMultiDeleteConfirmationDialog(BuildContext context) {
    final appState = Provider.of<MyAppState>(context, listen: false);
    
    if (appState.selectedFavorites.isEmpty) {
      // Show SnackBar if no items are selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No Item Selected')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Selected Suggestions'),
          content: Text('Are you sure you want to delete the selected suggestions?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                // Remove selected favorites
                appState.removeSelectedFavorites();
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    // For Lab Task 2: Add AppBar with Delete button
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Suggestions'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showMultiDeleteConfirmationDialog(context);
            },
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
              // Lab Task 2: Show checkmark for selected items
              trailing: appState.selectedFavorites.contains(pair)
                  ? Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                // Lab Task 2: Toggle selection when tapped
                appState.toggleSelection(pair);
              },
              // Lab Task 1: Show confirmation dialog on long press
              onLongPress: () {
                _showDeleteConfirmationDialog(context, pair);
              },
            ),
        ],
      ),
    );
  }
}