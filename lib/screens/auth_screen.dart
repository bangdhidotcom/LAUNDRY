import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/user_service.dart';
import '../main.dart'; // <--- PERBAIKAN 1: Tambahkan '../' agar bisa menemukan file main.dart

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final UserService _userService = UserService();
  bool _isLogin = true; // Toggle antara Login dan Daftar
  bool _isLoading = false;
  bool _isObscure = true;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // --- PROSES LOGIN ---
        await _userService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // --- PROSES DAFTAR ---
        if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
          throw Exception("Nama dan No HP wajib diisi");
        }
        await _userService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berhasil daftar! Silakan login.")),
          );
          setState(() => _isLogin = true); // Pindah ke tab login
          _isLoading = false;
          return;
        }
      }

      // Jika berhasil login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll("Exception: ", "")),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PERBAIKAN 2: Ganti icon ke Icons.local_laundry_service (Material) agar pasti ada
              const Icon(Icons.local_laundry_service,
                  size: 64, color: Color(0xFF2563EB)),

              const SizedBox(height: 16),
              Text(
                _isLogin ? "Selamat Datang Kembali" : "Buat Akun Baru",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? "Masuk untuk mulai mencuci"
                    : "Daftar pelanggan Laundry3B",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              if (!_isLogin) ...[
                _inputField(_nameController, "Nama Lengkap", LucideIcons.user),
                const SizedBox(height: 16),
                _inputField(_phoneController, "Nomor HP/WA", LucideIcons.phone,
                    type: TextInputType.phone),
                const SizedBox(height: 16),
              ],

              _inputField(_emailController, "Email", LucideIcons.mail,
                  type: TextInputType.emailAddress),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(LucideIcons.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon:
                        Icon(_isObscure ? LucideIcons.eye : LucideIcons.eyeOff),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(_isLogin ? "Masuk Sekarang" : "Daftar Akun",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "Belum punya akun? " : "Sudah punya akun? "),
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? "Daftar" : "Login",
                      style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? type}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
