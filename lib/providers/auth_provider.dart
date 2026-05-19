import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

final supabaseClientProvider = Provider((ref) => SupabaseConfig.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.client.auth.currentUser;
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();
  if (data == null) return null;
  return ProfileModel.fromJson(data);
});

class AuthNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }
    await _loadProfile(user.id);
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        state = AsyncValue.data(ProfileModel.fromJson(data));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> profileData,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await SupabaseConfig.client.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          ...profileData,
        });
        await _loadProfile(response.user!.id);
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        await _loadProfile(response.user!.id);
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    await SupabaseConfig.client
        .from('profiles')
        .update(data)
        .eq('id', user.id);
    await _loadProfile(user.id);
  }

  Future<void> deleteAccount() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    await SupabaseConfig.client.from('profiles').delete().eq('id', user.id);
    await SupabaseConfig.client.auth.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<ProfileModel?>>(
  (ref) => AuthNotifier(),
);
