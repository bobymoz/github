import 'package:flutter/material.dart';
import '../services/forum_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_text_field.dart';
import 'discussion_detail_screen.dart';

const kPrimary = Color(0xFF4D698E);

class CreateDiscussionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tags;
  const CreateDiscussionScreen({super.key, required this.tags});

  @override
  State<CreateDiscussionScreen> createState() => _CreateDiscussionScreenState();
}

class _CreateDiscussionScreenState extends State<CreateDiscussionScreen> {
  final _service = ForumService();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final Set<String> _selectedTagIds = {};
  bool _loading = false;

  Future<void> _create() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      showAppError(context, Exception('Preencha o título e a mensagem.'));
      return;
    }
    if (_selectedTagIds.isEmpty) {
      showAppError(context, Exception('Escolha ao menos uma categoria.'));
      return;
    }
    setState(() => _loading = true);
    try {
      final id = await _service.createDiscussion(_title.text.trim(), _content.text.trim(), _selectedTagIds.toList());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DiscussionDetailScreen(discussionId: id, title: _title.text.trim())),
      );
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Novo tópico'),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(controller: _title, label: 'Título'),
              const SizedBox(height: 14),
              AppTextField(controller: _content, label: 'Mensagem', maxLines: 6),
              const SizedBox(height: 16),
              const Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold, color: kPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tags.map((t) {
                  final selected = _selectedTagIds.contains(t['id']);
                  return FilterChip(
                    label: Text(t['name'] ?? ''),
                    selected: selected,
                    selectedColor: kPrimary.withOpacity(0.2),
                    checkmarkColor: kPrimary,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedTagIds.add(t['id']);
                      } else {
                        _selectedTagIds.remove(t['id']);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _loading ? null : _create,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Publicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
