import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/forum_service.dart';
import '../widgets/app_feedback.dart';

const kPrimary = Color(0xFF4D698E);

class DiscussionDetailScreen extends StatefulWidget {
  final String discussionId;
  final String title;

  const DiscussionDetailScreen({super.key, required this.discussionId, required this.title});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final _service = ForumService();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _sending = false;
  bool _canReply = true;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final discussion = await _service.fetchDiscussion(widget.discussionId);
      final result = await _service.fetchPosts(widget.discussionId);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(result['posts']);
        _canReply = discussion['canReply'] == true;
        _isLocked = discussion['isLocked'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) showAppError(context, e);
      setState(() => _loading = false);
    }
  }

  Future<void> _reply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.replyToDiscussion(widget.discussionId, text);
      _replyController.clear();
      await _load();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _posts.length,
                    itemBuilder: (context, i) {
                      final p = _posts[i];
                      final date = DateTime.tryParse(p['createdAt'] ?? '');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: kPrimary,
                                    backgroundImage: p['avatarUrl'] != null ? NetworkImage(p['avatarUrl']) : null,
                                    child: p['avatarUrl'] == null
                                        ? Text((p['username'] ?? '?').toString()[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  if (date != null)
                                    Text(DateFormat('dd/MM HH:mm').format(date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Html(html: p['contentHtml'] ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLocked || !_canReply)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 6),
                  Text('Este tópico está trancado.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Responder...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: kPrimary,
                      child: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _reply),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renderiza o HTML simples que o Flarum devolve (parágrafos, negrito, links,
/// listas). Não é um navegador completo, só o suficiente pra ler posts.
class Html extends StatelessWidget {
  final String html;
  const Html({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    final text = html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .trim();
    return Text(text, style: const TextStyle(fontSize: 15, height: 1.4));
  }
}
