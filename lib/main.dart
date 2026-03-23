import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 引入跳转功能

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.light().copyWith(primaryColor: Colors.green),
  home: LaoMaHome(),
));

class LaoMaHome extends StatefulWidget {
  @override
  _LaoMaHomeState createState() => _LaoMaHomeState();
}

class _LaoMaHomeState extends State<LaoMaHome> {
  final TextEditingController _controller = TextEditingController();

  // 核心跳转功能：点击后唤起浏览器
  Future<void> _goTo(String url) async {
    final Uri uri = Uri.parse(url);
    // 强制使用外部浏览器打开，这样最稳
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw '无法打开 $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('老马听书'), centerTitle: true, backgroundColor: Colors.white, foregroundColor: Colors.green, elevation: 0),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // 你的分享广告位
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
            child: Text("主打分享：MAKE老马\nV：q13978984", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
          ),
          SizedBox(height: 20),
          
          // --- 真正的搜索框：输入书名，回车即搜 ---
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search, // 键盘显示“搜索”图标
            decoration: InputDecoration(
              hintText: '输入书名，回车全网搜听书...',
              prefixIcon: Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                // 自动跳百度搜书
                _goTo("https://www.baidu.com/s?wd=$value 听书");
              }
            },
          ),
          
          SizedBox(height: 30),
          Text("精品推荐 (点击直达网页)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          
          // 这里我帮你预设了几个跳转链接，点一下就能跳走
          _bookItem("大奉打更人", "https://m.ting78.com/show/15945.html"),
          _bookItem("长宁帝军", "https://m.shuyinfm.com/video/4416.html"),
          _bookItem("剑来", "https://m.huanting.cc/book/182.html"),
          _bookItem("全网资源搜刮 (百度)", "https://www.baidu.com"),
        ],
      ),
    );
  }

  Widget _bookItem(String title, String url) {
    return ListTile(
      leading: Icon(Icons.play_circle_fill, color: Colors.green),
      title: Text(title),
      subtitle: Text("点击进入资源页"),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _goTo(url),
    );
  }
}
