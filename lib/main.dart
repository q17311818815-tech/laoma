import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(primaryColor: Colors.green),
      home: Scaffold(
        appBar: AppBar(title: Text('老马听书'), centerTitle: true, backgroundColor: Colors.white, foregroundColor: Colors.green, elevation: 0),
        body: ListView(
          padding: EdgeInsets.all(20),
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
              child: Text("主打分享：MAKE老马\nV：q13978984", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
            ),
            SizedBox(height: 20),
            TextField(decoration: InputDecoration(hintText: '搜书名、作者...', prefixIcon: Icon(Icons.search), filled: true, fillColor: Color(0xFFF5F5F5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none))),
            SizedBox(height: 30),
            Text("精品推荐", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(leading: Icon(Icons.book), title: Text("长宁帝军"), trailing: Icon(Icons.play_circle_fill, color: Colors.green)),
            ListTile(leading: Icon(Icons.book), title: Text("大奉打更人"), trailing: Icon(Icons.play_circle_fill, color: Colors.green)),
          ],
        ),
      ),
    ));
