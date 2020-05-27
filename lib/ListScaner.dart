import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'dialog/loading_dialog.dart';
import 'dialog/msg_dialog.dart';
import 'dialog/rich_dialog.dart';
import 'helper/DatabaseHelper.dart';
import 'model/ListQR.dart';
import 'package:http/http.dart' as http;

class ListScaner extends StatefulWidget {
  @override
  _ListScanerState createState() => _ListScanerState();
}

class _ListScanerState extends State<ListScaner> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<ListQR> todoList;
  int count = 0;
  List data;
  String Record_number;
  @override
  Widget build(BuildContext context) {
    if (todoList == null) {
      todoList = List<ListQR>();
      updateListView();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách đã lưu'),
      ),
      body: getTodoListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB clicked');

          // post data to server and delete all sqllit qr_code
          postDataDeleteAll();
        },
        tooltip: 'Add Todo',
        child: Icon(Icons.add),
      ),
    );
  }

  //delete all slqlite
  void postDataDeleteAll() async {
    var result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none)
      {
        RichDialog.WarningDialog(context, "Chưa kết nối Internet!","");
        //print("III : ");
      }
    else if(result == ConnectivityResult.mobile || result == ConnectivityResult.wifi)
      {

        //post data to kintone
        if(todoList.length != 0)
        {
          LoadingDialog.showLoadingDialog(context, "Đang tải....");
          //List<ListQR> list;
          for(int i=0; i<todoList.length;i++)
          {
          //_checkInOrcheckOut(i);


            //test
            ////lay ngay hien tai
            var now = new DateTime.now();
            String DateNow = ('${now.year}-${now.month}-${now.day}');

            ////lay ma code_app
            final prefsCode_app = await SharedPreferences.getInstance();
            final Code_app = prefsCode_app.getString('app') ?? 0;
            String url = 'https://kintoneivsdemo.cybozu.com/k/v1/records.json?app=$Code_app&query=date = "$DateNow" and staffCode="' + todoList[i].qrcode + '"';
            var response = await http.get(
              //encode the url
                Uri.encodeFull(url),
                //only accept json response
                headers: {"X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA=="}
            );
            print("url :" + url);

            print("response : " + response.body);
            var converDataToJson = json.decode(response.body);
            data = converDataToJson['records'];
            print("data :" + data.toString());
            final int statusCode = response.statusCode;
            if (statusCode == 200 || statusCode == 201)
            {

              if(data.length > 0)
              {
                Record_number = converDataToJson['records'][0]['Record_number']['value'];
                print("Record_number :" + Record_number);

                print("CHUAN BI checkOut");

                //checkOut
                // set up PUT request arguments
                String url = 'https://kintoneivsdemo.cybozu.com/k/v1/record.json';
                Map<String, String> headers = {
                  HttpHeaders.contentTypeHeader: "application/json", // or whatever
                  "X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA==",
                };

                //lay ma code_app
                final prefsCode_app = await SharedPreferences.getInstance();
                final Code_app = prefsCode_app.getString('app') ?? 0;
                print('read: $Code_app');

                String json = '{"app":"' + Code_app + '","id":"' + Record_number + '", "record": {"timeOut": {"value":"' + todoList[i].Time + '"}}}';
                print("URL : " + json);

                Response response = await put(url, headers: headers, body: json);
                // check the status code for the result
                int statusCode = response.statusCode;
                if(statusCode == 200 || statusCode == 201)
                {
                  String body = response.body;
                  print(body);
                  print("checkOut thành công !");
                  ////delete id data was post kintone
                  int result = await databaseHelper.deleteTodo(todoList[i].id);
                  print("delteID : " + result.toString());
                  //updateListView();

                }
                else
                {
                  print("checkOut không thành công !");

                }


                print("DA checkOut");

              }
              else if(data.length == 0)
              {
                print("CHUAN BI checkIn");
                //await _CheckIn(i);
                // set up POST request arguments
                String url = 'https://kintoneivsdemo.cybozu.com/k/v1/records.json';
                Map<String, String> headers = {
                  HttpHeaders.contentTypeHeader: "application/json", // or whatever
                  "X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA==",
                };

                //lay email tu SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                final key = 'email';
                final value = prefs.getString(key) ?? 0;
                print('read: $value');


                //lay ma code_app
                final prefsCode_app = await SharedPreferences.getInstance();
                final Code_app = prefsCode_app.getString('app') ?? 0;
                print('read: $Code_app');



                String json = '{"app" : "'+ Code_app +'","records" : [{"driverCode" : {"value" : "'+ value +'"},"staffCode" : {"value" : "' + todoList[i].qrcode + '"},"date" : {"value" : "'+ todoList[i].Date +'"},"timeIn" : {"value" : "'+ todoList[i].Time +'"}}]}';

                // make POST request
                print("URL : " + json);

                Response response = await post(url, headers: headers, body: json);

                // check the status code for the result
                int statusCode = response.statusCode;
                if(statusCode == 200 || statusCode == 201)
                {
                  String body = response.body;
                  print(body);
                  print("checkIn thành công !");

                  ////delete id data was post kintone
                  int result = await databaseHelper.deleteTodo(todoList[i].id);
                  print("deleteID : " + result.toString());
                  //updateListView();
                }
                else
                {
                  print("checkIn không thành công !");
                }


                print("DA CHECK IN");

              }


            }
            else
              MsgDialog.showMsgDialog(context, DateNow.toString(), "error");

          }
          updateListView();//update ListScaner
          LoadingDialog.hideLoadingDialog(context);



        }
        else
          RichDialog.WarningDialog(context, "Danh Sách Rỗng !", "");
      }


  }

//  //xu ly kiem tra là checkIn hay checkOut
//  _checkInOrcheckOut(int i) async{
//
//    //RichDialog.SuccesDialog(context, "đã quét", "");
//
//    ////lay ngay hien tai
//    var now = new DateTime.now();
//    String DateNow = ('${now.year}-${now.month}-${now.day}');
//
//    ////lay ma code_app
//    final prefsCode_app = await SharedPreferences.getInstance();
//    final Code_app = prefsCode_app.getString('app') ?? 0;
//    print('read: $Code_app');
//
//    String url = 'https://kintoneivsdemo.cybozu.com/k/v1/records.json?app=$Code_app&query=date = "$DateNow" and staffCode="' + todoList[i].qrcode + '"';
//
//    var response = await http.get(
//      //encode the url
//        Uri.encodeFull(url),
//        //only accept json response
//        headers: {"X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA=="}
//    );
//    print("url :" + url);
//
//    print("response : " + response.body);
//    var converDataToJson = json.decode(response.body);
//    data = converDataToJson['records'];
//    print("data :" + data.toString());
//    final int statusCode = response.statusCode;
//    if (statusCode == 200 || statusCode == 201)
//    {
//
//      if(data.length > 0)
//      {
//        Record_number = converDataToJson['records'][0]['Record_number']['value'];
//        print("Record_number :" + Record_number);
//
//
//        print("CHUAN BI CHECK OUT");
//        await _CheckOut(Record_number,i);
//        print("DA CHECK OUT");
//
//      }
//      if(data.length <= 0 )
//      {
//        print("CHUAN BI CHECK IN");
//        await _CheckIn(i);
//        print("DA CHECK IN");
//
//
//      }
//
//
//    }
//    else
//      MsgDialog.showMsgDialog(context, DateNow.toString(), "error");
//
//
//  }
//
//  //post data checkOut
//  _CheckOut(String Record_number,int i) async {
//    // set up PUT request arguments
//    String url = 'https://kintoneivsdemo.cybozu.com/k/v1/record.json';
//    Map<String, String> headers = {
//      HttpHeaders.contentTypeHeader: "application/json", // or whatever
//      "X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA==",
//    };
//
//    //lay time hien tai
//    var now = new DateTime.now();
//    String TimeNow = ('${now.hour}:${now.minute}');
//
//    //lay ma code_app
//    final prefsCode_app = await SharedPreferences.getInstance();
//    final Code_app = prefsCode_app.getString('app') ?? 0;
//    print('read: $Code_app');
//
//    String json = '{"app":"' + Code_app + '","id":"' + Record_number + '", "record": {"timeOut": {"value":"' + todoList[i].Time + '"}}}';
//    print("URL : " + json);
//
//    Response response = await put(url, headers: headers, body: json);
//    // check the status code for the result
//    int statusCode = response.statusCode;
//    if(statusCode == 200 || statusCode == 201)
//    {
//      String body = response.body;
//      print(body);
//      print("checkOut thành công !");
//      ////delete id data was post kintone
//      int result = await databaseHelper.deleteTodo(todoList[i].id);
//      print("delteID : " + result.toString());
//      updateListView();
//
//    }
//    else
//    {
//      print("checkOut không thành công !");
//
//    }
//
//  }
//
//  //post data checkIn
//  _CheckIn(int i) async {
//    // set up POST request arguments
//    String url = 'https://kintoneivsdemo.cybozu.com/k/v1/records.json';
//    Map<String, String> headers = {
//      HttpHeaders.contentTypeHeader: "application/json", // or whatever
//      "X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA==",
//    };
//
//    //lay email tu SharedPreferences
//    final prefs = await SharedPreferences.getInstance();
//    final key = 'email';
//    final value = prefs.getString(key) ?? 0;
//    print('read: $value');
//
//    //lay ngay hien tai
//    var now = new DateTime.now();
//    String DateNow = ('${now.year}-${now.month}-${now.day}');
//
//    //lay time hien tai
//    String TimeNow = ('${now.hour}:${now.minute}');
//
//    //lay ma code_app
//    final prefsCode_app = await SharedPreferences.getInstance();
//    final Code_app = prefsCode_app.getString('app') ?? 0;
//    print('read: $Code_app');
//
//
//
//    String json = '{"app" : "'+ Code_app +'","records" : [{"driverCode" : {"value" : "'+ value +'"},"staffCode" : {"value" : "' + todoList[i].qrcode + '"},"date" : {"value" : "'+ todoList[i].Date +'"},"timeIn" : {"value" : "'+ todoList[i].Time +'"}}]}';
//
//    // make POST request
//    print("URL : " + json);
//
//    Response response = await post(url, headers: headers, body: json);
//
//    // check the status code for the result
//    int statusCode = response.statusCode;
//    if(statusCode == 200 || statusCode == 201)
//    {
//      String body = response.body;
//      print(body);
//      print("checkIn thành công !");
//
//      ////delete id data was post kintone
//      int result = await databaseHelper.deleteTodo(todoList[i].id);
//      print("delteID : " + result.toString());
//      updateListView();
//    }
//    else
//    {
//      print("checkIn không thành công !");
//    }
//
//  }

  ListView getTodoListView() {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (BuildContext context, int position) {
        return Card(
          color: Colors.white,
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text(getFirstLetter(this.todoList[position].qr_code),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(this.todoList[position].qrcode,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(this.todoList[position].Time + " " + this.todoList[position].Date),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  child: Icon(Icons.delete,color: Colors.red,),
                  onTap: () {
                    _delete(context, todoList[position]);
                  },
                ),
              ],
            ),
//            onTap: () {
//              debugPrint("ListTile Tapped");
//              navigateToDetail(this.todoList[position], 'Edit Todo');
//            },
          ),
        );
      },
    );
  }

  //láy 2 string add image
  getFirstLetter(String title) {
    return title.substring(0, 2);
  }

  //delete QR with id
  void _delete(BuildContext context, ListQR todo) async {
    int result = await databaseHelper.deleteTodo(todo.id);
    if (result != 0) {
      //MsgDialog.showMsgDialog(context, "Đã xóa !","");
      RichDialog.SuccesDialog(context, "Đã xóa !","");
      updateListView();
    }
  }

  //update lại ListView
  void updateListView() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<ListQR>> todoListFuture = databaseHelper.getTodoList();
      todoListFuture.then((todoList) {
        setState(() {
          this.todoList = todoList;
          this.count = todoList.length;
        });
      });
    });
  }

}
