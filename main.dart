import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
  home: LaoMaProApp(),
));

class LaoMaProApp extends StatefulWidget {
  @override
  _LaoMaProAppState createState() => _LaoMaProAppState();
}

class _LaoMaProAppState extends State<LaoMaProApp> {
  final TextEditingController _input = TextEditingController();
  List<Map<String, String>> _results = [];
  List<String> _favorites = []; // 收藏夹
  bool _isSearching = false;
  String? _currentTitle; // 当前正在听的书名
  String? _currentUrl; // 当前播放页面地址
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // 加载本地收藏
  _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _favorites = prefs.getStringList('favs') ?? []);
  }

  // 保存收藏
  _toggleFav(String title) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(title)) _favorites.remove(title);
    else _favorites.add(title);
    await prefs.setStringList('favs', _favorites);
    setState(() {});
  }

  // 大厂级去广告搜索逻辑
  Future<void> _proSearch(String key) async {
    setState(() => _isSearching = true);
    try {
      final res = await Dio().get("https://www.baidu.com/s?wd=$key 听书");
      final doc = parse(res.data);
      final items = doc.querySelectorAll('div.result.c-container');
      _results = items.map((e) => {
        'title': e.querySelector('h3.t > a')?.text ?? '',
        'url': e.querySelector('h3.t > a')?.attributes['href'] ?? '',
      }).where((m) => m['title']!.isNotEmpty).toList();
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 纯净播放页：注入 JS 屏蔽网页广告
  void _openPlayer(String title, String url) {
    setState(() {
      _currentTitle = title;
      _currentUrl = url;
    });
    
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // 核心：大厂黑科技，自动清理网页里的广告元素和弹窗
          _webController?.runJavaScript("""
            document.querySelectorAll('.ad, .banner, .download-btn, #footer').forEach(e => e.remove());
            console.log('广告已清理');
          """);
        },
      ))
      ..loadRequest(Uri.parse(url));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          children: [
            Container(margin: EdgeInsets.all(12), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: Icon(_favorites.contains(title) ? Icons.favorite : Icons.favorite_border, color: Colors.red), onPressed: () => _toggleFav(title)),
                ],
              ),
            ),
            Expanded(child: WebViewWidget(controller: _webController!)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(title: Text('老马听书 Pro', style: TextStyle(fontWeight: FontWeight.w900)), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 头部搜索区
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(15),
                        width: double.infinity,
                        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green[400]!, Colors.green[700]!]), borderRadius: BorderRadius.circular(15)),
                        child: Text("老马私藏：全网资源·纯净直达\nV: q13978984", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _input,
                        decoration: InputDecoration(
                          hintText: "搜书名、作者...",
                          prefixIcon: Icon(Icons.search),
                          filled: true, fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          suffixIcon: IconButton(icon: Icon(Icons.send), onPressed: () => _proSearch(_input.text)),
                        ),
                        onSubmitted: _proSearch,
                      ),
                    ],
                  ),
                ),
              ),
              
              // 收藏夹区域
              if (_results.isEmpty && _favorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("我的书架", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Wrap(spacing: 10, children: _favorites.map((f) => ActionChip(label: Text(f), onPressed: () => _proSearch(f))).toList()),
                      ],
                    ),
                  ),
                ),

              // 搜索结果
              _isSearching 
                ? SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Card(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        elevation: 0, color: Colors.white,
                        child: ListTile(
                          leading: Container(width: 45, height: 45, decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: Icon(Icons.menu_book, color: Colors.green)),
                          title: Text(_results[index]['title']!, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                          subtitle: Text("点击进入纯净播放模式"),
                          trailing: Icon(Icons.play_arrow_rounded, size: 30, color: Colors.green),
                          onTap: () => _openPlayer(_results[index]['title']!, _results[index]['url']!),
                        ),
                      ),
                      childCount: _results.length,
                    ),
                  ),
            ],
          ),
          
          // 大厂级底部迷你控制条
          if (_currentTitle != null)
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: GestureDetector(
                onTap: () => _openPlayer(_currentTitle!, _currentUrl!),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)]),
                  child: Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.green),
                      SizedBox(width: 10),
                      Expanded(child: Text("正在听：$_currentTitle", style: TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis)),
                      Icon(Icons.pause_circle_filled, color: Colors.white, size: 35),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
