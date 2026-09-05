import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/data/auth_store.dart';
import 'package:mobile/data/firebase_auth_repository.dart';
import 'package:mobile/data/username_store.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _register = false;
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _store = AuthStore();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: Text(_register ? 'Kayıt ol' : 'Giriş yap'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/culturebox_icon.png',
              width: 104,
              height: 104,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _register
              ? 'Kendi listeni oluştur.'
              : 'Listene kaldığın yerden devam et.',
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _register
              ? 'İzleyeceklerini, oynayacaklarını ve okuyacaklarını kaydet.'
              : 'Hesabına giriş yap, listen tüm cihazlarında seninle olsun.',
          style: const TextStyle(color: AppColors.muted, fontSize: 15),
        ),
        const SizedBox(height: 24),
        if (_register) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Adın',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı adı',
              helperText: 'Profilin @kullanici_adi olarak görünür.',
              prefixText: '@',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-posta',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Şifre',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: () async {
            if (_busy) return;
            setState(() {
              _busy = true;
              _error = null;
            });
            if (_register && _name.text.trim().isEmpty) {
              setState(() {
                _busy = false;
                _error = 'Ad alanını doldur.';
              });
              return;
            }
            if (_register &&
                UsernameStore().validationError(_username.text) != null) {
              setState(() {
                _busy = false;
                _error = UsernameStore().validationError(_username.text);
              });
              return;
            }
            final success = _register
                ? await _store.register(
                    _name.text,
                    _email.text,
                    _password.text,
                    _username.text,
                  )
                : await _store.signIn(_email.text, _password.text);
            if (!mounted) return;
            if (success) {
              Navigator.pop(context, true);
            } else if (mounted) {
              setState(() {
                _busy = false;
                _error = _store.lastError;
              });
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_register ? 'Kayıt ol' : 'Giriş yap'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.destructive),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('veya', style: TextStyle(color: AppColors.muted)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  final success = await _store.signInWithGoogle();
                  if (!mounted) return;
                  if (success) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _busy = false;
                      _error = _store.lastError;
                    });
                  }
                },
          icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
          label: const Text('Google ile devam et'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _register = !_register),
          child: Text(
            _register
                ? 'Zaten hesabın var mı? Giriş yap'
                : 'Hesabın yok mu? Kayıt ol',
          ),
        ),
        if (!_register)
          TextButton(
            onPressed: () async {
              if (!_email.text.contains('@')) {
                setState(() => _error = 'Önce e-posta adresini gir.');
                return;
              }
              try {
                await FirebaseAuthRepository().sendPasswordReset(_email.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sıfırlama bağlantısı gönderildi.'),
                    ),
                  );
                }
              } on FirebaseAuthException catch (error) {
                if (mounted) setState(() => _error = authErrorMessage(error));
              }
            },
            child: const Text('Şifremi unuttum'),
          ),
      ],
    ),
  );
}
