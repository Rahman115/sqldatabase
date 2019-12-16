import 'dart:io';

import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TodoItem {
  final int id;
  final String content;
  final bool isDone;
  final DateTime createAt;

  TodoItem({this.id, this.content, this.isDone = false, this.createAt});

  TodoItem.fromJsonMap(Map<String, dynamic> map)
      : id = map['id'],
        content = map['content'],
        isDone = map['isDone'] == 1,
        createAt = DateTime.fromMillisecondsSinceEpoch(map['createAt']);

  Map<String, dynamic> toJsonMap() => {
        'id': id,
        'content': content,
        'isDone': isDone ? 1 : 0,
        'createAt': createAt.millisecondsSinceEpoch,
      };
}

class SqlPage extends StatefulWidget {
  SqlPage({Key key}) : super(key: key);

  @override
  _SqlPageState createState() => _SqlPageState();
}

class _SqlPageState extends State<SqlPage> {
  static const _DbFileName = 'sqflite_ex.db';
  static const _DbTableName = 'example_tbl';

  final AsyncMemoizer _memozer = AsyncMemoizer();

  Database _db;
  List<TodoItem> _todos = [];

  Future<void> _initDb() async {
    final dbFolder = await getDatabasesPath();
    if (!await Directory(dbFolder).exists()) {
      await Directory(dbFolder).create(recursive: true);
    }

    final dbPath = join(dbFolder, _DbFileName);

    this._db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
      CREATE TABLE $_DbTableName(
        id INTEGER PRIMARY KEY,
        isDone BIT NOT NULL,
        content TEXT,
        createAt INT
      )
      ''');
      },
    );
  }

  Future<void> _getTodoItem() async {
    var sql = 'SELECT * FROM $_DbTableName';
    List<Map> json = await this._db.rawQuery(sql);

    print('${json.length} rows retrieved from DB!');

    this._todos = json.map((js) => TodoItem.fromJsonMap(js)).toList();
  }

  Future<void> _addTodoItem(TodoItem todo) async {
    await this._db.transaction(
      (Transaction txn) async {
        int id = await txn.rawInsert('''
          INSERT INTO $_DbTableName
            (content, isDone, createdAt)
          VALUES
            (
              "${todo.content}",
              ${todo.isDone ? 1 : 0}, 
              ${todo.createAt.millisecondsSinceEpoch}
            )''');
        print('Inserted todo item with id=$id.');
      },
    );
  }

  Future<void> _toogleTodoItem(TodoItem todo) async {
    int count = await this._db.rawUpdate('''
    UPDATE $_DbTableName SET isDone = ? 
    WHERE id = ?
    ''', [todo.isDone ? 0 : 1, todo.id]);

    print('Update $count record in DB!');
  }

  Future<void> _deleteTodoItem(TodoItem todo) async {
    int count = await this._db.rawDelete('''
    DELETE FROM $_DbTableName 
    WHERE id = ${todo.id}
    ''');

    print('Update $count record in DB!');
  }

  Future<bool> _asyncInit() async {
    await _memozer.runOnce(() async {
      await _initDb();
      await _getTodoItem();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _asyncInit(),
      // initialData: InitialData,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Scaffold(
          body: ListView(
            children: this._todos.map(_itemToListTile).toList(),
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  Future<void> _updateUI() async {
    await _getTodoItem();
    setState(() {});
  }

  ListTile _itemToListTile(TodoItem todo) => ListTile(
        title: Text(
          todo.content,
          style: TextStyle(
              fontStyle: todo.isDone ? FontStyle.italic : null,
              color: todo.isDone ? Colors.grey : null,
              decoration: todo.isDone ? TextDecoration.lineThrough : null),
        ),
        subtitle: Text('id = ${todo.id}\nCreated at ${todo.createAt}'),
        isThreeLine: true,
        leading: IconButton(
          icon: Icon(
              todo.isDone ? Icons.check_box : Icons.check_box_outline_blank),
          onPressed: () async {
            await _toogleTodoItem(todo);
            _updateUI();
          },
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () async {
            await _deleteTodoItem(todo);
            _updateUI();
          },
        ),
      );

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () async {
        await _addTodoItem(TodoItem(
          content: 'news',
          createAt: DateTime.now(),
        ));
        _updateUI();
      },
    );
  }
}
