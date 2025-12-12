// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/pages/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); // Tambahan untuk register
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true; // Toggle Login/Register
  String? _errorMessage;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Email dan password wajib diisi');
      return;
    }

    if (!_isLoginMode && name.isEmpty) {
       setState(() => _errorMessage = 'Nama wajib diisi untuk pendaftaran');
       return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLoginMode) {
        // --- LOGIKA LOGIN ---
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.session != null) {
          Get.offAll(() => const MainPage());
        }
      } else {
        // --- LOGIKA REGISTER ADMIN ---
        final AuthResponse res = await _supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        if (res.user != null) {
          // Masukkan ke tabel 'admins'
          await _supabase.from('admins').insert({
            'id': res.user!.id,
            'email': email,
            'name': name,
            'role': 'admin', // Default role
            'created_at': DateTime.now().toIso8601String(),
          });
          
          Get.snackbar(
            'Berhasil', 
            'Akun admin berhasil dibuat, silakan login.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM
          );
          
          setState(() => _isLoginMode = true); // Pindah ke mode login
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi Dark/Light Mode dari sistem
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.blueAccent : const Color(0xFF005f9f);
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.grey[100];
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_3b.png',
                  height: 100,
                  color: primaryColor,
                  colorBlendMode: BlendMode.modulate,
                ),
                const SizedBox(height: 24),

                Text(
                  _isLoginMode ? 'Admin Login' : 'Admin Register',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode ? 'Masuk untuk mengelola laundry' : 'Daftarkan admin baru',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 40),

                // Nama Field (Hanya saat Register)
                if (!_isLoginMode) ...[
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nama Lengkap',
                    icon: Icons.person,
                    cardColor: cardColor,
                    textColor: textColor,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  inputType: TextInputType.emailAddress,
                  cardColor: cardColor,
                  textColor: textColor,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: primaryColor,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: cardColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Box
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isLoginMode ? 'Masuk' : 'Daftar',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle Login/Register
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _errorMessage = null;
                      _emailController.clear();
                      _passwordController.clear();
                      _nameController.clear();
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isLoginMode ? 'Belum punya akun? ' : 'Sudah punya akun? ',
                      style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.black54),
                      children: [
                        TextSpan(
                          text: _isLoginMode ? 'Daftar Admin' : 'Login Disini',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    required Color cardColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: cardColor,
      ),
    );
  }
}