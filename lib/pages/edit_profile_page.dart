import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/tunisia_wilayas.dart';
import '../services/supabase_service.dart';
import '../services/image_utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _selectedWilaya;
  File? _newAvatar;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authNotifierProvider).valueOrNull;
    if (profile != null) {
      _nameCtrl.text = profile.fullName ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _selectedWilaya = profile.wilaya;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryBlue),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryPink),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImageUtils.pickAndCompress(source: source);
    if (file != null) setState(() => _newAvatar = file);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String? avatarUrl;
      if (_newAvatar != null) {
        final path = '${const Uuid().v4()}.jpg';
        await SupabaseConfig.client.storage
            .from('avatars')
            .upload(path, _newAvatar!);
        avatarUrl = SupabaseConfig.client.storage
            .from('avatars')
            .getPublicUrl(path);
      }

      await ref.read(authNotifierProvider.notifier).updateProfile({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'wilaya': _selectedWilaya ?? '',
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil mis à jour'),
              backgroundColor: successColor),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: const Text('Modifier le profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: primaryBlue.withOpacity(0.1),
                    backgroundImage: _newAvatar != null
                        ? FileImage(_newAvatar!) as ImageProvider
                        : profile?.avatarUrl != null
                            ? NetworkImage(profile!.avatarUrl!)
                            : null,
                    child: (_newAvatar == null && profile?.avatarUrl == null)
                        ? const Icon(Icons.person, size: 56, color: primaryBlue)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Nom complet',
              controller: _nameCtrl,
              prefix: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Téléphone',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefix: const Icon(Icons.phone_outlined),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedWilaya,
              hint: const Text('Gouvernorat'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on_outlined),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: tunisiaWilayas
                  .map((w) =>
                      DropdownMenuItem(value: w, child: Text(w)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedWilaya = v),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Sauvegarder',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
