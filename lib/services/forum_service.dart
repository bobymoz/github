import 'flarum_api.dart';

class ForumService {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;
  ForumService._internal();

  final _api = FlarumApi.instance;
  Map<String, dynamic>? _cachedUser;

  Map<String, dynamic>? get currentUser => _cachedUser;
  String? get currentUserId => _api.userId;
  bool get isLoggedIn => _api.token != null;

  Future<bool> loadSession() async {
    await _api.loadSession();
    if (_api.token == null || _api.userId == null) return false;
    try {
      _cachedUser = await fetchUser(_api.userId!);
      return true;
    } catch (_) {
      await _api.clearSession();
      return false;
    }
  }

  // ---------- Auth ----------

  Future<void> login(String identification, String password) async {
    final res = await _api.post('/token', {
      'identification': identification,
      'password': password,
      'remember': true,
    });
    await _api.setSession(res['token'] as String, res['userId'] as String);
    _cachedUser = await fetchUser(res['userId'] as String);
  }

  Future<void> register(String username, String email, String password) async {
    await _api.post('/users', {
      'data': {
        'attributes': {'username': username, 'email': email, 'password': password},
      },
    });
    // Cadastro feito; loga em seguida com as mesmas credenciais.
    await login(username, password);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post('/forgot', {
      'data': {
        'attributes': {'email': email},
      },
    });
  }

  Future<void> signOut() async {
    await _api.clearSession();
    _cachedUser = null;
  }

  Future<Map<String, dynamic>> fetchUser(String id) async {
    final res = await _api.get('/users/$id');
    return (res['data'] as Map<String, dynamic>)['attributes'];
  }

  // ---------- Tags (categorias) ----------

  Future<List<Map<String, dynamic>>> fetchTags() async {
    final res = await _api.get('/tags');
    final data = List<Map<String, dynamic>>.from(res['data']);
    return data.map((t) => t['attributes'] as Map<String, dynamic>..['id'] = t['id']).toList();
  }

  // ---------- Discussões ----------

  Future<Map<String, dynamic>> fetchDiscussions({int offset = 0, String? tagId, String? filter}) async {
    final params = <String, String>{
      'page[offset]': '$offset',
      'page[limit]': '20',
      'include': 'user,lastPostedUser,tags,firstPost',
      'sort': '-lastPostedAt',
    };
    if (tagId != null) params['filter[tag]'] = tagId;
    if (filter != null && filter.isNotEmpty) params['filter[q]'] = filter;
    final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');

    final res = await _api.get('/discussions?$query');
    final index = indexIncluded(res['included'] as List?);
    final raw = List<Map<String, dynamic>>.from(res['data']);

    final discussions = raw.map((d) {
      final user = resolveToOne(d, 'user', index);
      final tags = resolveToMany(d, 'tags', index);
      final firstPost = resolveToOne(d, 'firstPost', index);
      final attrs = d['attributes'] as Map<String, dynamic>;
      return {
        'id': d['id'],
        'title': attrs['title'],
        'commentCount': attrs['commentCount'],
        'createdAt': attrs['createdAt'],
        'lastPostedAt': attrs['lastPostedAt'],
        'isLocked': attrs['isLocked'] == true,
        'isSticky': attrs['isSticky'] == true,
        'username': user?['attributes']?['displayName'] ?? user?['attributes']?['username'] ?? '?',
        'avatarUrl': user?['attributes']?['avatarUrl'],
        'tags': tags.map((t) => {'id': t['id'], 'name': t['attributes']?['name'], 'color': t['attributes']?['color']}).toList(),
        'excerpt': _stripHtml(firstPost?['attributes']?['contentHtml'] as String?),
      };
    }).toList();

    return {
      'discussions': discussions,
      'hasMore': (res['links'] as Map<String, dynamic>?)?['next'] != null,
    };
  }

  Future<Map<String, dynamic>> fetchDiscussion(String id) async {
    final res = await _api.get('/discussions/$id?include=user,tags');
    final index = indexIncluded(res['included'] as List?);
    final d = res['data'] as Map<String, dynamic>;
    final user = resolveToOne(d, 'user', index);
    final tags = resolveToMany(d, 'tags', index);
    final attrs = d['attributes'] as Map<String, dynamic>;
    return {
      'id': d['id'],
      'title': attrs['title'],
      'commentCount': attrs['commentCount'],
      'canReply': attrs['canReply'] ?? true,
      'isLocked': attrs['isLocked'] == true,
      'username': user?['attributes']?['displayName'] ?? user?['attributes']?['username'] ?? '?',
      'tags': tags.map((t) => {'id': t['id'], 'name': t['attributes']?['name']}).toList(),
    };
  }

  Future<Map<String, dynamic>> fetchPosts(String discussionId, {int offset = 0}) async {
    final params = {
      'filter[discussion]': discussionId,
      'page[offset]': '$offset',
      'page[limit]': '20',
      'include': 'user',
      'sort': 'number',
    };
    final query = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final res = await _api.get('/posts?$query');
    final index = indexIncluded(res['included'] as List?);
    final raw = List<Map<String, dynamic>>.from(res['data']);

    final posts = raw.where((p) => p['attributes']?['contentType'] == 'comment').map((p) {
      final user = resolveToOne(p, 'user', index);
      final attrs = p['attributes'] as Map<String, dynamic>;
      return {
        'id': p['id'],
        'number': attrs['number'],
        'contentHtml': attrs['contentHtml'],
        'createdAt': attrs['createdAt'],
        'username': user?['attributes']?['displayName'] ?? user?['attributes']?['username'] ?? '?',
        'avatarUrl': user?['attributes']?['avatarUrl'],
        'userId': user?['id'],
      };
    }).toList();

    return {
      'posts': posts,
      'hasMore': (res['links'] as Map<String, dynamic>?)?['next'] != null,
    };
  }

  Future<String> createDiscussion(String title, String content, List<String> tagIds) async {
    final res = await _api.post('/discussions', {
      'data': {
        'type': 'discussions',
        'attributes': {'title': title, 'content': content},
        'relationships': {
          'tags': {
            'data': tagIds.map((id) => {'type': 'tags', 'id': id}).toList(),
          },
        },
      },
    });
    return (res['data'] as Map<String, dynamic>)['id'] as String;
  }

  Future<void> replyToDiscussion(String discussionId, String content) async {
    await _api.post('/posts', {
      'data': {
        'type': 'posts',
        'attributes': {'content': content},
        'relationships': {
          'discussion': {
            'data': {'type': 'discussions', 'id': discussionId},
          },
        },
      },
    });
  }

  String? _stripHtml(String? html) {
    if (html == null) return null;
    final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length > 140 ? '${text.substring(0, 140)}...' : text;
  }
}
