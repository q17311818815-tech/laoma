import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // 引入网络请求功能
import 'package:html/parser.dart' show parse; // 引入网页解析功能
import 'package:webview_flutter/webview_flutter.dart'; // 引入内置网页功能（最后展示资源用）

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
  final TextEditingController _inputController = TextEditingController();
  List<Map<String, String>> _searchResults = []; // 存储搜索结果
  bool _isLoading = false; // 是否正在加载

  @override
  void initState() {
    super.initState();
  }

  // --- 核心逻辑：悄悄去后台搜百度，把干净的资源“抠”出来 ---
  Future<void> _searchAudioBook(String bookName) async {
    setState(() {
      _isLoading = true;
      _searchResults = []; // 清空之前的搜索结果
    });

    try {
      final dio = Dio();
      // 这里我悄悄设置了浏览器的头，防止被百度反爬虫
      dio.options.headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      };
      
      // 核心：请求百度的听书资源
      final response = await dio.get("https://www.baidu.com/s?wd=$bookName 听书");
      
      if (response.statusCode == 200) {
        final document = parse(response.data);
        // 这是关键步骤：悄悄解析网页内容，抠出“资源标题”和“链接”
        final results = document.querySelectorAll('div.result.c-container');

        final searchList = <Map<String, String>>[];
        for (final result in results) {
          final title = result.querySelector('h3.t > a')?.text ?? '';
          final url = result.querySelector('h3.t > a')?.attributes['href'] ?? '';
          if (title.isNotEmpty && url.isNotEmpty) {
            searchList.add({'title': title, 'url': url});
          }
        }
        
        setState(() {
          _searchResults = searchList;
        });
      }
    } catch (e) {
      print('搜书出错了: $e');
    } finally {
      setState(() {
        _isLoading = false; // 加载完成
      });
    }
  }

  // 最后直达资源页面，在 App 内部开，不露浏览器壳子
  late final WebViewController _webController;
  void _openPage(String url) {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(url));

    Navigator.of(context).push(
      MaterialBar(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('老马听书'), centerTitle: true, backgroundColor: Colors.white, foregroundColor: Colors.green, elevation: 1,),
          body: WebViewWidget(controller: _webController),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('老马听书', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 1, centerTitle: true,),
      body: Column(
        children: [
          // 首页固定：广告 + 搜索框
          _buildHomeHeader(),
          
          // 下半部分：根据状态显示（加载中、结果列表、精品推荐）
          Expanded(
            child: _isLoading ? _buildLoading() : (_searchResults.isNotEmpty ? _buildSearchResultsList() : _build精品推荐()),
          ),
        ],
      ),
    );
  }

  // 首页：广告 + 搜索框
  Widget _buildHomeHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
            child: Text("主打分享：MAKE老马\nV：q13978984", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
          ),
          SizedBox(height: 25),
          
          // --- 搜索框：回车直接在 App 内悄悄全网搜 ---
          TextField(
            controller: _inputController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '输入书名，App 内自家搜索引擎...',
              prefixIcon: Icon(Icons.search, color: Colors.green),
              filled: true,
              fillColor: Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _searchAudioBook(value); // 核心：调用自家的搜索引擎大脑
              }
            },
          ),
        ],
      ),
    );
  }

  // 加载中界面：没有任何进度条，只有转圈圈图标
  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(color: Colors.green));
  }

  // --- 真正的美观、纯净搜索结果列表 ---
  Widget _buildSearchResultsList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[200]), // 干净的分隔线
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.language, color: Colors.green),
          title: Text(result['title']!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[900])),
          trailing: Icon(Icons.chevron_right, color: Colors.green),
          onTap: () => _openPage(result['url']!), // 点击后秒开资源，没有任何浏览器界面
        );
      },
    );
  }

  // 默认：精品推荐 (点击直达)
  Widget _build精品推荐() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      children: [
        SizedBox(height: 10),
        Text("精品推荐 (App 内自家美观界面)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        _bookItem("大奉打更人", "https://m.ting78.com/"),
        _bookItem("书音FM", "https://m.shuyinfm.com/"),
        _bookItem("听书168", "https://m.tingshu168.com/"),
      ],
    );
  }

  Widget _bookItem(String title, String url) {
    return ListTile(
      leading: Icon(Icons.play_circle_fill, color: Colors.green),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.chevron_right),
      onTap: () => _openPage(url),
    );
  }
}
