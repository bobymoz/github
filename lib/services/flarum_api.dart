import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FlarumException implements Exception {
  final String message;
  FlarumException(this.message);
  @override
  String toString() => message;
}

/// Cliente de baixo nível pra API JSON:API do Flarum.
/// Guarda o token de acesso (obtido via POST /api/token) de forma segura.
class FlarumApi {
  static const String baseUrl = 'https://forum.bitbrit.website/api';

  static final FlarumApi instance = FlarumApi._internal();
  factory FlarumApi() => instance;
  FlarumApi._internal();

  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;

  Future<void> loadSession() async {
    _token = await _storage.read(key: 'flarum_token');
    _userId = await _storage.read(key: 'flarum_user_id');
  }

  Future<void> setSession(String token, String userId) async {
    _token = token;
    _userId = userId;
    await _storage.write(key: 'flarum_token', value: token);
    await _storage.write(key: 'flarum_user_id', value: userId);
  }

  Future<void> clearSession() async {
    _token = null;
    _userId = null;
    await _storage.delete(key: 'flarum_token');
    await _storage.delete(key: 'flarum_user_id');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/vnd.api+json',
        'Accept': 'application/vnd.api+json',
        if (_token != null) 'Authorization': 'Token $_token',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    Map<String, dynamic>? json;
    try {
      json = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : null;
    } catch (_) {
      json = null;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json ?? {};
    }
    final errors = json?['errors'] as List?;
    String message = 'Algo deu errado. Tente novamente.';
    if (errors != null && errors.isNotEmpty) {
      final first = errors.first as Map<String, dynamic>;
      message = (first['detail'] as String?) ?? (first['code'] as String?) ?? message;
    }
    throw FlarumException(message);
  }
}

/// Indexa os recursos de "included" por "tipo:id" pra resolver relacionamentos
/// (padrão JSON:API) sem precisar de requisições extras.
Map<String, Map<String, dynamic>> indexIncluded(List? included) {
  final map = <String, Map<String, dynamic>>{};
  if (included == null) return map;
  for (final item in included) {
    final m = item as Map<String, dynamic>;
    map['${m['type']}:${m['id']}'] = m;
  }
  return map;
}

Map<String, dynamic>? resolveToOne(
  Map<String, dynamic> resource,
  String relName,
  Map<String, Map<String, dynamic>> index,
) {
  final rel = resource['relationships']?[relName]?['data'];
  if (rel == null || rel is! Map) return null;
  return index['${rel['type']}:${rel['id']}'];
}

List<Map<String, dynamic>> resolveToMany(
  Map<String, dynamic> resource,
  String relName,
  Map<String, Map<String, dynamic>> index,
) {
  final rel = resource['relationships']?[relName]?['data'];
  if (rel == null || rel is! List) return [];
  return rel
      .map((r) => index['${r['type']}:${r['id']}'])
      .whereType<Map<String, dynamic>>()
      .toList();
}
