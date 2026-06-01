import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';

/// Handles authentication: login, register, logout
/// Manages JWT token persistence and socket connection lifecycle
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final isLoading = false.obs;
  final isLoggedIn = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  /// Check if user has a saved session and auto-login
  void _checkExistingSession() {
    final token = StorageService.to.getToken();
    final user = StorageService.to.getUser();

    if (token != null && token.isNotEmpty && user != null) {
      currentUser.value = user;
      isLoggedIn.value = true;

      // Connect socket with stored token
      SocketService.to.connect(token);
      _emitUserOnline();
    }
  }

  /// Register a new user
  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (password.length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    try {
      final response = await ApiService.to.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      final data = response.data;
      if (data['success'] == true) {
        final token = data['data']['token'];
        final user = UserModel.fromJson(data['data']['user']);

        // Persist session
        await StorageService.to.saveToken(token);
        await StorageService.to.saveUser(user);

        currentUser.value = user;
        isLoggedIn.value = true;

        // Connect socket
        SocketService.to.connect(token);
        _emitUserOnline();

        // Clear form
        _clearForm();

        // Navigate to home
        Get.offAllNamed('/home');
      }
    } catch (e) {
      debugPrint('Register error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Login existing user
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;

    try {
      final response = await ApiService.to.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      if (data['success'] == true) {
        final token = data['data']['token'];
        final user = UserModel.fromJson(data['data']['user']);

        // Persist session
        await StorageService.to.saveToken(token);
        await StorageService.to.saveUser(user);

        currentUser.value = user;
        isLoggedIn.value = true;

        // Connect socket
        SocketService.to.connect(token);
        _emitUserOnline();

        // Clear form
        _clearForm();

        // Navigate to home
        Get.offAllNamed('/home');
      }
    } catch (e) {
      debugPrint('Login error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout — disconnect socket, clear storage, navigate to login
  Future<void> logout() async {
    isLoading.value = true;

    // Disconnect socket first
    SocketService.to.disconnect();

    // Clear all stored data
    await StorageService.to.clearAll();

    currentUser.value = null;
    isLoggedIn.value = false;
    isLoading.value = false;

    // Navigate to login
    Get.offAllNamed('/login');
  }

  void _emitUserOnline() {
    if (currentUser.value != null) {
      SocketService.to.emit('user_online', {
        'userId': currentUser.value!.id,
      });
    }
  }

  void _clearForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
