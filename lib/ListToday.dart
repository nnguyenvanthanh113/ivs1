import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ivs1/model/ListQRToday.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/ListQRToday.dart';
class ListToday extends StatefulWidget {
  @override
  _ListTodayState createState() => _ListTodayState();
}

class _ListTodayState extends State<ListToday> {

  List<ListQRToday> listqrToday = new List();

  //ham get api map List
  Future<String> getData() async {

    ////lay ngay hien tai
    var now = new DateTime.now();
    String DateNow = ('${now.year}-${now.month}-${now.day}');

    ////lay ma code_app
    final prefsCode_app = await SharedPreferences.getInstance();
    final Code_app = prefsCode_app.getString('app') ?? 0;
    String url = 'https://kintoneivsdemo.cybozu.com/k/v1/records.json?app=$Code_app&query=date = "$DateNow"';
    var response = await http.get(
      //encode the url
        Uri.encodeFull(url),
        //only accept json response
        headers: {"X-Cybozu-Authorization" : "cHR0aHVAaW5kaXZpc3lzLmpwOnB0dGh1MTIzNA=="}
    );
    print("url :" + url);

    setState(() {
      var converDataToJson = json.decode(response.body)['records'] as List;
      listqrToday = converDataToJson.map((tagJson) => ListQRToday.fromJson(tagJson)).toList();
    });


    print("listqrToday" + listqrToday.toString());
    print("mang 0 :" + listqrToday[0].qrcode.toString());
  }

  @override
  void initState() {
    super.initState();
    this.getData();
    print("length :" + listqrToday.length.toString());
  }
  @override
  Widget build(BuildContext context) {
//    if (listqrToday == null) {
//      listqrToday = List<ListQRToday>();
//      getData();
//      setState(() {
//        this.listqrToday = listqrToday;
//      });
//    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách trong ngày'),
      ),
      body:  ListView.builder(
        itemCount:  listqrToday.length,
        itemBuilder: (BuildContext context, int position) {
//          return Center(
//            child: Card(
//              child: Column(
//                mainAxisSize: MainAxisSize.min,
//                children: <Widget>[
//                  const ListTile(
//                    leading: Icon(Icons.album),
//                    title: Text(listqrToday[0].qrcode.toString()),
//                    subtitle: Text('Music by Julie Gable. Lyrics by Sidney Stein.'),
//                  ),
//
//                  ButtonBar(
//                    children: <Widget>[
//                      FlatButton(
//                        child: const Text('xin chao'),
//                        color: Colors.lightBlueAccent,
//                        //onPressed: () {/* ... */},
//                      ),
//                      FlatButton(
//                        child: const Text('LISTEN'),
//                        color: Colors.lightBlueAccent,
//                        //onPressed: () {/* ... */},
//                      ),
//                    ],
//                  ),
//                ],
//              ),
//            ),
//          );
          return Card(
            color: Colors.white,
            elevation: 2.0,
            child: ListTile(
              leading: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.amber,
                child: Text(this.listqrToday[position].qrcode,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text(this.listqrToday[position].staffName,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              //subtitle: Text(this.listqrToday[position].timeIn + " " +   this.listqrToday[position].timeOut == null ? '' : this.listqrToday[position].timeOut),
              subtitle: Text(this.listqrToday[position].timeIn + this.listqrToday[position].timeOut),

            ),
          );
        },
      ),
    );
  }



  //láy 2 string add image
  getFirstLetter(String title) {
    return title.substring(0, 2);
  }

}
