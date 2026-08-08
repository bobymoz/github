import 'package:flutter/material.dart';
import '../services/forum_service.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_text_field.dart';
import 'discussions_list_screen.dart';

const kPrimary = Color(0xFF4D698E);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _service = ForumService();
  final _identification = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await _service.register(_username.text.trim(), _email.text.trim(), _password.text);
      } else {
        await _service.login(_identification.text.trim(), _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DiscussionsListScreen()),
        (route) => false,
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icon/app_icon.png', width: 84, height: 84),
                ),
                const SizedBox(height: 16),
                Text(_isSignUp ? 'Criar conta' : 'Entrar', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (_isSignUp) ...[
                  AppTextField(controller: _username, label: 'Nome de usuário'),
                  const SizedBox(height: 12),
                  AppTextField(controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                ] else ...[
                  AppTextField(controller: _identification, label: 'Usuário ou email'),
                  const SizedBox(height: 12),
                ],
                AppTextField(controller: _password, label: 'Senha', isPassword: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isSignUp ? 'Cadastrar' : 'Entrar'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? 'Já tem conta? Entrar' : 'Não tem conta? Cadastre-se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
