import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D1A), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
              )),
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF6C63FF)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF4ECDC4).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 32),
              const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Join ChatFlow and start messaging', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
              const SizedBox(height: 40),
              _field(auth.nameController, 'Full Name', 'Enter your name', Icons.person_outline),
              const SizedBox(height: 20),
              _field(auth.emailController, 'Email', 'Enter your email', Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _field(auth.passwordController, 'Password', 'Min 6 characters', Icons.lock_outline, obscure: true),
              const SizedBox(height: 36),
              Obx(() => SizedBox(
                width: double.infinity, height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF6C63FF)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF4ECDC4).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton(
                    onPressed: auth.isLoading.value ? null : auth.register,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: auth.isLoading.value
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
              const SizedBox(height: 28),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Already have an account? ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                GestureDetector(onTap: () => Get.back(), child: const Text('Sign In', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 14, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint, IconData icon, {TextInputType type = TextInputType.text, bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF4ECDC4).withOpacity(0.2))),
        child: TextField(controller: c, keyboardType: type, obscureText: obscure, style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)), prefixIcon: Icon(icon, color: const Color(0xFF4ECDC4), size: 22), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
      ),
    ]);
  }
}
