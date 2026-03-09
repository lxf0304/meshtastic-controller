import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MeshtasticApp());
}

class MeshtasticApp extends StatelessWidget {
  const MeshtasticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeshtasticProvider(),
      child: MaterialApp(
        title: 'Meshtastic Controller',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.cyan,
            brightness: Brightness.dark,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}

// ============== Provider ==============
class MeshtasticProvider extends ChangeNotifier {
  String _baseUrl = 'http://192.168.3.76';
  Map<String, dynamic>? _nodeInfo;
  List<Map<String, dynamic>> _messages = [];
  bool _isConnected = false;
  bool _isLoading = false;

  String get baseUrl => _baseUrl;
  Map<String, dynamic>? get nodeInfo => _nodeInfo;
  List<Map<String, dynamic>> get messages => _messages;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;

  void setBaseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }

  Future<void> fetchNodeInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/v1/router'));
      if (response.statusCode == 200) {
        _nodeInfo = json.decode(response.body);
        _isConnected = true;
      }
    } catch (e) {
      _isConnected = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/v1/router/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'channel': 0,
        }),
      );
      _messages.add({
        'text': text,
        'from': 'Me',
        'time': DateTime.now().toIso8601String(),
      });
      notifyListeners();
    } catch (e) {
      // handle error
    }
  }
}

// ============== Home Page ==============
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardPage(),
          MessagesPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: '状态'),
          NavigationDestination(icon: Icon(Icons.message), label: '消息'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

// ============== Dashboard Page ==============
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshtasticProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('MESHTASTIC'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.fetchNodeInfo,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildListDelegate([
                  _buildStatusCard(
                    '连接状态',
                    provider.isConnected ? '在线' : '离线',
                    provider.isConnected ? Icons.wifi : Icons.wifi_off,
                    provider.isConnected ? Colors.green : Colors.red,
                  ),
                  _buildStatusCard(
                    '节点数',
                    provider.nodeInfo?['nodeNum']?.toString() ?? '--',
                    Icons.hub,
                    Colors.cyan,
                  ),
                  _buildStatusCard(
                    '电池',
                    '${provider.nodeInfo?['deviceMetrics']?['batteryLevel'] ?? 0}%',
                    Icons.battery_full,
                    Colors.orange,
                  ),
                  _buildStatusCard(
                    '信号',
                    '${provider.nodeInfo?['deviceMetrics']?.signalStrength ?? 0} dBm',
                    Icons.signal_cellular_alt,
                    Colors.purple,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============== Messages Page ==============
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshtasticProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('消息'),
            actions: [
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    provider.sendMessage(_controller.text);
                    _controller.clear();
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.messages[index];
                    final isMe = msg['from'] == 'Me';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.cyan.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['text']),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: '输入消息...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          provider.sendMessage(_controller.text);
                          _controller.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============== Settings Page ==============
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<MeshtasticProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.wifi),
                title: const Text('设备地址'),
                subtitle: Text(provider.baseUrl),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(text: provider.baseUrl);
                      return AlertDialog(
                        title: const Text('修改设备地址'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(hintText: 'http://192.168.x.x'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.setBaseUrl(controller.text);
                              Navigator.pop(context);
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('关于'),
                subtitle: const Text('Meshtastic Controller v1.0.0'),
              ),
            ],
          );
        },
      ),
    );
  }
}
