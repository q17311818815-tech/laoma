import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(primaryColor: Colors.green),
      home: Scaffold(
        appBar: AppBar(
          title: Text('老马听书'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.green,
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // 顶部老马专属广告
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Text(
                "主打分享：MAKE老马\nV：q13978984",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
            ),
            SizedBox(height: 20),
            // 搜索框
            TextField(
              decoration: InputDecoration(
                hintText: '搜书名、作者，老马带你听...',
                prefixIcon: Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 30),
            Text("精品推荐", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildBookItem("长宁帝军", "热血玄幻"),
            _buildBookItem("大奉打更人", "探案修仙"),
            _buildBookItem("剑来", "江湖路远"),
          ],
        ),
      ),
    ));

Widget _buildBookItem(String title, String desc) {
  return ListTile(
    leading: Icon(Icons.book, color: Colors.green[200]),
    title: Text(title),
    subtitle: Text(desc),
    trailing: Icon(Icons.play_circle_fill, color: Colors.green),
    onTap: () {}, // 之后打包好的版本点击会跳转
  );
}
