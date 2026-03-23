import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
  home: MainNavigation(),
));

// --- 底部双栏导航架构 ---
class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [LaoMaSearchPage(), LaoMaUserPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: '搜索发现'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '个人中心'),
        ],
      ),
    );
  }
}

// --- 页面一：大厂级搜索发现页 ---
class LaoMaSearchPage extends StatefulWidget {
  @override
  _LaoMaSearchPageState createState() => _LaoMaSearchPageState();
}

class _LaoMaSearchPageState extends State<LaoMaSearchPage> {
  final TextEditingController _input = TextEditingController();
  List<Map<String, String>> _results = [];
  List<String> _suggestions = [];
  bool _isLoading = false;

  // 1. 实时获取关联书名
  Future<void> _getSuggestions(String query) async {
    if (query.isEmpty) { setState(() => _suggestions = []); return; }
    try {
      final res = await Dio().get("https://suggestion.baidu.com/5a?wd=$query");
      String data = res.data.toString();
      if (data.contains("s:[")) {
        String s = data.split("s:[")[1].split("]")[0];
        List<String> list = s.split(",").map((e) => e.replaceAll('"', '')).toList();
        setState(() => _suggestions = list.take(6).toList());
      }
    } catch (e) {}
  }

  // 2. 执行搜索
  Future<void> _search(String key) async {
    if (key.isEmpty) return;
    setState(() { _isLoading = true; _suggestions = []; FocusScope.of(context).unfocus(); });
    try {
      final res = await Dio().get("https://www.baidu.com/s?wd=${Uri.encodeComponent(key + " 听书")}");
      final doc = parse(res.data);
      final items = doc.querySelectorAll('div.result.c-container');
      setState(() => _results = items.map((e) => {
        'title': e.querySelector('h3.t > a')?.text ?? '未知资源',
        'url': e.querySelector('h3.t > a')?.attributes['href'] ?? '',
      }).where((m) => m['url']!.isNotEmpty).toList());
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(title: Text('老马听书 Pro'), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              children: [
                TextField(
                  controller: _input,
                  onChanged: _getSuggestions,
                  decoration: InputDecoration(
                    hintText: "输入书名，点击飞机搜索",
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(icon: Icon(Icons.send, color: Colors.green), onPressed: () => _search(_input.text)),
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                  onSubmitted: _search,
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                    child: Column(children: _suggestions.map((s) => ListTile(title: Text(s), dense: true, onTap: () { _input.text = s; _search(s); })).toList()),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) => Card(
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.play_circle_filled, color: Colors.green),
                  title: Text(_results[index]['title']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text("全网资源 · 纯净解析"),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LaoMaPlayer(url: _results[index]['url']!, title: _results[index]['title']!))),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 页面二：纯净播放器（不弹浏览器） ---
class LaoMaPlayer extends StatelessWidget {
  final String url;
  final String title;
  LaoMaPlayer({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: WebViewWidget(controller: controller),
    );
  }
}

// --- 页面三：个人中心与设置页 ---
class LaoMaUserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, 60, 20, 40),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.green[100], child: Icon(Icons.person, size: 50, color: Colors.green)),
                SizedBox(width: 20),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("老马至尊会员", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("永久免费听书权限", style: TextStyle(color: Colors.grey)),
                ]),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                children: [
                  _item(Icons.history, "播放历史记录"),
                  _item(Icons.favorite_border, "我的收藏书籍"),
                  _item(Icons.delete_outline, "清除应用缓存"),
                  _item(Icons.update, "当前版本：v2.1.0 (已是最新)"),
                  Divider(),
                  _item(Icons.headset_mic_outlined, "联系老马客服：q13978984", color: Colors.green),
                  _item(Icons.info_outline, "关于老马听书：由 Flutter 强力驱动"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title, style: TextStyle(color: color, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
