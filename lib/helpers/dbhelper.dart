import 'dart:io';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqldatabase/models/contact_model.dart';

class DbHelper {
  static DbHelper _dbHelper;
  static Database _database;

  // final AsyncMem

  DbHelper._createObject();

  factory DbHelper() {
    if (_dbHelper == null) {
      _dbHelper = DbHelper._createObject();
    }

    return _dbHelper;
  }

  Future<Database> initDb() async {
    Directory directory = await getApplicationDocumentsDirectory();

    String path = directory.path + 'contact.db';

    var todoDatabase = openDatabase(path, version: 1, onCreate: _createDb);

    return todoDatabase;
  }

  void _createDb(Database db, int version) async {
    await db.execute('''
        CREATE TABLE contact (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT, 
          phone TEXT)
          ''');
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initDb();
    }
    return _database;
  }

  Future<List<Map<String, dynamic>>> select() async {
    Database db = await this.database;
    var mapList = await db.query('contact', orderBy: 'name');
    return mapList;
  }

//create databases
  Future<int> insert(ContactModel object) async {
    Database db = await this.database;
    int count = await db.insert('contact', object.toMap());
    return count;
  }

//update databases
  Future<int> update(ContactModel object) async {
    Database db = await this.database;
    int count = await db.update('contact', object.toMap(),
        where: 'id=?', whereArgs: [object.id]);
    return count;
  }

//delete databases
  Future<int> delete(int id) async {
    Database db = await this.database;
    int count = await db.delete('contact', where: 'id=?', whereArgs: [id]);
    return count;
  }

  Future<List<ContactModel>> getContactList() async {
    var contactMapList = await select();
    int count = contactMapList.length;
    List<ContactModel> contactList = List<ContactModel>();
    for (int i = 0; i < count; i++) {
      contactList.add(ContactModel.fromMap(contactMapList[i]));
    }
    return contactList;
  }
}
