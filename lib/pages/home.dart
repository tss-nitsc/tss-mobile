import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// for QR Code
import 'dart:convert';
import 'package:barcode_scan/barcode_scan.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String organizationName = '';
  String organizationDescription = '';
  String ticketNumber = '';

  @override
  initState() {
    loadData();
    super.initState();
  }

  void resetData() {
    setState(() {
      organizationName = '';
      organizationDescription = '';
      ticketNumber = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (organizationName != '') {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Ticket'),
        ),
        body: Container(
          padding: EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(
                        // leading: Icon(Icons.restaurant,
                        //     size: 40.0, color: Colors.grey),
                        title: Text(
                          organizationName,
                          style: TextStyle(fontSize: 20.0),
                        ),
                        subtitle: Text(
                          organizationDescription,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.check, size: 24.0, color: Colors.grey),
                            CurrentTicketNumber(organizationName),
                            Icon(Icons.access_time,
                                size: 24.0, color: Colors.grey),
                            Text(' 5 min', style: TextStyle(fontSize: 20.0)),
                          ],
                        ),
                      ),
                      Text('Ticket Number'),
                      Text(
                        ticketNumber,
                        style: TextStyle(
                          fontSize: 48.0,
                          fontWeight: FontWeight.normal,
                          fontStyle: FontStyle.normal,
                          color: Colors.teal,
                        ),
                      ),
                      ButtonTheme.bar(
                        child: ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('DELETE'),
                              onPressed: () {
                                deleteData();
                                resetData();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            readQRCode();
          },
          // 長押し時の説明文
          tooltip: 'Read QR code',
          child: Icon(Icons.camera_alt),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Ticket'),
        ),
        body: Container(
          padding: EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'There is no numbered ticket. Please read the QR Code from the bottom right button.',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            readQRCode();
          },
          // 長押し時の説明文
          tooltip: 'Read QR code',
          child: Icon(Icons.camera_alt),
        ),
      );
    }
  }

  Future readQRCode() async {
    try {
      String data = await BarcodeScanner.scan();
      Map<String, dynamic> map = json.decode(data);
      setState(() {
        organizationName = map['organizationName'];
        organizationDescription = map['organizationDescription'];
        ticketNumber = map['ticketNumber'];
      });
      List<String> list = [
        organizationName,
        organizationDescription,
        ticketNumber
      ];
      saveData(list);
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        // setState(() {
        //   //this.data = 'The user did not grant the camera permission!';
        // });
      } else {
        // setState(() {
        //   //this.data = 'Unknown error: $e';
        // });
      }
    } on FormatException {
      // setState(() {
      //   //this.data = 'null (User returned using the "back"-button before scanning anything. Result)';
      // });
    } catch (e) {
      // setState(() {
      //   //this.data = 'Unknown error: $e';
      // });
    }
  }

  static const String key = 'numberedTicket';

  saveData(List<String> list) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setStringList(key, list);
  }

  loadData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    List<String> data = pref.getStringList(key);
    if (data != null) {
      setState(() {
        organizationName = data[0];
        organizationDescription = data[1];
        ticketNumber = data[2];
      });
    }
  }

  deleteData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.remove(key);
  }
}

class CurrentTicketNumber extends StatelessWidget {
  CurrentTicketNumber(this.organizationName);
  final String organizationName;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance
          .collection('organizations')
          .where('name', isEqualTo: organizationName)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Text('Loading...');
          default:
            return Text(
              ' ' +
                  snapshot.data.documents[0]['current_ticket_number']
                      .toString() +
                  ' ',
              style: TextStyle(fontSize: 20.0),
            );
        }
      },
    );
  }
}
