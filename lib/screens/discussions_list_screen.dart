import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/forum_service.dart';
import '../widgets/app_feedback.dart';
import 'discussion_detail_screen.dart';
import 'create_discussion_screen.dart';
import 'auth_screen.dart';

const kPrimary = Color(0xFF4D698E);

class DiscussionsListScreen extends StatefulWidget {
  const DiscussionsListScreen({super.key});

  @override
  State<DiscussionsListScreen> createState() => _DiscussionsListScreenState();
}

class _DiscussionsListScreenState extends State<DiscussionsListScreen> {
  final _service = ForumService();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _discussions = [];
  List<Map<String, dynamic>> _tags = [];
  String? _activeTagId;
  String? _activeTagName;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final tags = await _service.fetchTags();
      final result = await _service.fetchDiscussions(tagId: _activeTagId);
      setState(() {
        _tags = tags;
        _discussions = List<Map<String, dynamic>>.from(result['discussions']);
        _hasMore = result['hasMore'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showAppError(context, e);
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.fetchDiscussions(offset: _discussions.length, tagId: _activeTagId);
      setState(() {
        _discussions = [..._discussions, ...List<Map<String, dynamic>>.from(result['discussions'])];
        _hasMore = result['hasMore'] == true;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _filterByTag(String? tagId, String? tagName) {
    Navigator.pop(context);
    setState(() {
      _activeTagId = tagId;
      _activeTagName = tagName;
    });
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/icon/app_icon.png', width: 40, height: 40),
                    ),
                    const SizedBox(width: 12),
                    Text(_service.currentUser?['username'] ?? 'Suckit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.forum_outlined, color: kPrimary),
                title: const Text('Todos os tópicos'),
                selected: _activeTagId == null,
                onTap: () => _filterByTag(null, null),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
              ),
              Expanded(
                child: ListView(
                  children: _tags.map((t) {
                    final color = _parseColor(t['color']);
                    return ListTile(
                      leading: Icon(Icons.label_outline, color: color ?? kPrimary),
                      title: Text(t['name'] ?? ''),
                      selected: _activeTagId == t['id'],
                      onTap: () => _filterByTag(t['id'], t['name']),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sair'),
                onTap: () async {
                  await _service.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        title: Text(_activeTagName ?? 'Suckit'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateDiscussionScreen(tags: _tags)),
        ).then((_) => _loadInitial()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo tópico', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: _discussions.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Nenhum tópico ainda.', style: TextStyle(color: Colors.grey))),
                    ])
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: _discussions.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i >= _discussions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final d = _discussions[i];
                        final date = DateTime.tryParse(d['lastPostedAt'] ?? d['createdAt'] ?? '');
                        final tags = List<Map<String, dynamic>>.from(d['tags'] ?? []);
                        return ListTile(
                          tileColor: Colors.white,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: kPrimary,
                            backgroundImage: d['avatarUrl'] != null ? NetworkImage(d['avatarUrl']) : null,
                            child: d['avatarUrl'] == null
                                ? Text((d['username'] ?? '?').toString()[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                                : null,
                          ),
                          title: Row(
                            children: [
                              if (d['isSticky'] == true) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 14, color: kPrimary)),
                              Expanded(child: Text(d['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (d['isLocked'] == true) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_outline, size: 14, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'por ${d['username']}${date != null ? " · ${DateFormat('dd/MM HH:mm').format(date)}" : ""} · ${d['commentCount']} resp.',
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 6,
                                    children: tags.map((t) => Chip(
                                          label: Text(t['name'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                          backgroundColor: _parseColor(t['color']) ?? kPrimary,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        )).toList(),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DiscussionDetailScreen(discussionId: d['id'], title: d['title'] ?? '')),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      var h = hex.replaceFirst('#', '');
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
