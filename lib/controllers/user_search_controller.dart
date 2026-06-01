import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Controller for searching users to start new conversations
/// Features debounced search input
class UserSearchController extends GetxController {
  final searchController = TextEditingController();
  final users = <UserModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  Timer? _debounceTimer;

  /// Search users with debounce (300ms delay)
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      users.clear();
      hasSearched.value = false;
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(query.trim());
    });
  }

  /// Fetch all users (for initial list)
  Future<void> fetchAllUsers() async {
    isLoading.value = true;
    try {
      final response = await ApiService.to.get('/users');
      final data = response.data;

      if (data['success'] == true) {
        users.value = (data['data']['users'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
      }
    } catch (e) {
      debugPrint('Fetch users error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Search users by query
  Future<void> _searchUsers(String query) async {
    isLoading.value = true;
    hasSearched.value = true;
    try {
      final response = await ApiService.to.get(
        '/users/search',
        queryParameters: {'q': query},
      );
      final data = response.data;

      if (data['success'] == true) {
        users.value = (data['data']['users'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
      }
    } catch (e) {
      debugPrint('Search users error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
