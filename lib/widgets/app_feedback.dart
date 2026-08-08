import 'package:flutter/material.dart';
import '../services/flarum_api.dart';

const kPrimary = Color(0xFF4D698E);
const kDanger = Color(0xFFB3261E);

String friendlyMessage(Object error) {
  if (error is FlarumException) return error.message;
  final raw = error.toString().toLowerCase();
  if (raw.contains('network') || raw.contains('socketexception') || raw.contains('failed host lookup')) {
    return 'Sem conexão com o servidor. Verifique sua internet.';
  }
  return 'Algo deu errado. Tente novamente.';
}

void showAppError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kDanger,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(friendlyMessage(error), style: const TextStyle(color: Colors.white))),
        ],
      ),
    ),
  );
}

void showAppSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
    ),
  );
}
