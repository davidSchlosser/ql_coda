import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:coda/logger.dart';

Logger _logger = getLogger('query_model', Level.debug);

const String defaultQuery = '!mood=/[a-z]/';

final queryProvider = StateProvider<String>((ref) {
  return  defaultQuery;
});

// TODO migrate from  ChangeNotifiers to RiverPod

class QueryModel extends ChangeNotifier {
  TextEditingController? textController;

  QueryModel() {
    textController ??= TextEditingController();
  }

  String get text => textController!.text;

  set text(String s) {
    textController!.text = s;
    notifyListeners();
  }
}

class SavedQueriesModel extends ChangeNotifier {
  static Map<String, String> queries = {};

  static const defaultFilters = <String, String>{
    'Added recently': '&(#(lastplayed > 20 days), #(added < 20 days))',
    'Any - no mood': '!mood=/[a-z]/',
    'Classical - no mood': '&(genre=/^Classical/, !mood=/[a-z]/)',
    'Jazz - no mood': '&(genre=/^Jazz/, !mood=/[a-z]/)'
  };

  SavedQueriesModel(){
    if (queries.isEmpty) {loadQueriesFromFile();}
  }

  Future<Map<String, dynamic>> loadQueriesFromFile() async {
    //final Map<String, dynamic> savedFilters = {};

    final directory = await getApplicationDocumentsDirectory();
    final File queriesFile = File('${directory.path}/saved_queries.txt');
    if (await queriesFile.exists()) {
      _logger.d('queries file exists');
      String str = await queriesFile.readAsString();
      //_logger.d('queries file: $str');
      Map<String, dynamic> j = const JsonDecoder().convert(str);
      Map<String, String> jStr = j.map((key, value) => MapEntry(key, value.toString()));
      queries.addAll(jStr);
    } else {
      _logger.d("queries file doesn't exist");
      queries.addAll(defaultFilters);
    }

    notifyListeners();
    return queries;
  }

  // add a new named query & update the file store
  Future save(String name, String query) async {
    queries[name] = query;
    await overWriteQueriesFile();
    notifyListeners();
  }

  // remove a named query & update the file store
  Future unSave(String name) async {
    queries.remove(name);
    await overWriteQueriesFile();
    notifyListeners();
  }

  static Future overWriteQueriesFile() async {

    final directory = await getApplicationDocumentsDirectory();
    final File queriesFile = File('${directory.path}/saved_queries.txt');
    if (await queriesFile.exists()) {
      await queriesFile.delete();
    }
    await queriesFile.writeAsString(jsonEncode(queries),
        mode: FileMode.append, flush: true);
  }

}
