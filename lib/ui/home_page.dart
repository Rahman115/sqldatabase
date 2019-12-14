import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqldatabase/helpers/dbhelper.dart';
import 'package:sqldatabase/models/contact_model.dart';
import 'package:sqldatabase/ui/entryform.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DbHelper dbHelper = DbHelper();
  int count = 0;
  List<ContactModel> contactList; 
  
  @override
  Widget build(BuildContext context) {
    if (contactList == null) {
      contactList = List<ContactModel>();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('data'),
      ),
      body: createListView(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: 'Tambah Data',
        onPressed: () async {
          var contact = await navigateToEntryForm(context, null);
          if (contact != null) addContact(contact);
        },
      ),
    );
  }

  Future<ContactModel> navigateToEntryForm(BuildContext context, ContactModel contact) async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return EntryForm(contact);
        }
      ) 
    );
    return result;
  }

  ListView createListView() {
    TextStyle textStyle = Theme.of(context).textTheme.subhead;
    return ListView.builder(
      itemCount: count,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          color: Colors.white,
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.people),
            ),
            title: Text(this.contactList[index].name, style: textStyle,),
            subtitle: Text(this.contactList[index].phone),
            trailing: GestureDetector(
              child: Icon(Icons.delete),
              onTap: () {
                deleteContact(contactList[index]);
              },   
            ),
            onTap: () async {
              var contact = await navigateToEntryForm(context, this.contactList[index]);
              if (contact != null) editContact(contact);
            },
          ),
        );
      },
    );
  }

  //buat contact
  void addContact(ContactModel object) async {
    int result = await dbHelper.insert(object);
    if (result > 0) {
      updateListView();
    }
  }
    //edit contact
  void editContact(ContactModel object) async {
    int result = await dbHelper.update(object);
    if (result > 0) {
      updateListView();
    }
  }

//delete contact
  void deleteContact(ContactModel object) async {
    int result = await dbHelper.delete(object.id);
    if (result > 0) {
      updateListView();
    }
  }
  //update contact
  void updateListView() {
    final Future<Database> dbFuture = dbHelper.initDb();
    dbFuture.then((database) {
      Future<List<ContactModel>> contactListFuture = dbHelper.getContactList();
      contactListFuture.then((contactList) {
        setState(() {
          this.contactList = contactList;
          this.count = contactList.length;
        });
      });
    });
  }
}
