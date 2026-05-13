import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/l10n/app_localizations.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _avatarUrl;
  File? _avatarFile;
  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          
          setState(() {
            _firstNameController.text = firstName;
            _lastNameController.text = lastName;
            _emailController.text = user.email ?? '';
            _avatarUrl = data['avatarUrl'];
            _originalFirstName = firstName;
            _originalLastName = lastName;
            _originalAvatarUrl = data['avatarUrl'] ?? '';
          });
        }
      } catch (e) {
        print('[EDIT PROFILE ERROR] Failed to load user data: $e');
      }
    }
  }

  bool _hasChanges() {
    final currentFirstName = _firstNameController.text.trim();
    final currentLastName = _lastNameController.text.trim();
    
    return currentFirstName != _originalFirstName || 
           currentLastName != _originalLastName ||
           _avatarFile != null || // Новое изображение выбрано
           (_avatarUrl != _originalAvatarUrl && _avatarUrl != null); // URL изменился
  }

  Future<void> _pickImage() async {
    try {
      print('[EDIT PROFILE] Starting image picker...');
      
      XFile? pickedFile;
      
      // Пробуем сначала gallery, потом camera как fallback
      try {
        final picker = ImagePicker();
        pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 70,
        );
      } catch (e) {
        print('[EDIT PROFILE] Gallery picker error: $e');
        
        // Пробуем camera как fallback
        try {
          final picker = ImagePicker();
          pickedFile = await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 512,
            maxHeight: 512,
            imageQuality: 70,
          );
        } catch (cameraError) {
          print('[EDIT PROFILE] Camera picker error: $cameraError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.translate('failedToPickImage')),
                backgroundColor: AppColors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
      
      if (pickedFile != null) {
        print('[EDIT PROFILE] Image picked successfully: ${pickedFile.path}');
        
        final file = File(pickedFile.path);
        
        // Проверяем что файл существует
        if (await file.exists()) {
          setState(() {
            _avatarFile = file;
          });
          print('[EDIT PROFILE] Avatar file set: ${file.path}');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected file does not exist'),
                backgroundColor: AppColors.red,
              ),
            );
          }
        }
      } else {
        print('[EDIT PROFILE] No image selected');
      }
    } catch (e) {
      print('[EDIT PROFILE ERROR] Failed to pick image: $e');
      
      if (mounted) {
        String errorMessage = 'Failed to pick image';
        
        // Более детальные сообщения об ошибках
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission')) {
          errorMessage = 'Permission denied. Please check your app permissions.';
        } else if (errorString.contains('cancelled')) {
          errorMessage = 'Image selection was cancelled';
          return; // Не показываем ошибку если пользователь отменил
        } else if (errorString.contains('unavailable')) {
          errorMessage = 'Image picker is not available on this device';
        } else if (errorString.contains('channel-error')) {
          errorMessage = 'Image picker channel error. Try using camera instead.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _uploadAvatarToStorage(File imageFile, String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child(userId)
          .child('avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      print('[EDIT PROFILE] Avatar uploaded to: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[EDIT PROFILE ERROR] Failed to upload avatar: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Сначала загружаем аватар если он выбран
        String? newAvatarUrl = _avatarUrl;
        if (_avatarFile != null) {
          print('[EDIT PROFILE] Uploading new avatar...');
          newAvatarUrl = await _uploadAvatarToStorage(_avatarFile!, user.uid);
          if (newAvatarUrl == null) {
            throw Exception('Failed to upload avatar');
          }
        }

        // Подготавливаем данные для обновления
        final updateData = <String, dynamic>{
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'displayName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Добавляем avatarUrl только если он изменился
        if (newAvatarUrl != _originalAvatarUrl) {
          updateData['avatarUrl'] = newAvatarUrl;
        }

        print('[EDIT PROFILE] Data changed, updating...');
        
        // Обновляем данные в Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);

        // Обновляем displayName в Firebase Auth
        await user.updateDisplayName(updateData['displayName']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.translate('profileUpdated')),
              backgroundColor: AppColors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Ждем немного перед закрытием
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.pop(context, true); // Возвращаем true чтобы обновить профиль
          }
        }
      }
    } catch (e) {
      print('[EDIT PROFILE ERROR] Failed to update profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.translate('editProfile'),
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Аватар
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _avatarFile != null
                            ? Image.file(
                                _avatarFile!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                            : _avatarUrl != null
                                ? Image.network(
                                    _avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildDefaultAvatar(),
                                  )
                                : _buildDefaultAvatar(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Имя
              _buildSectionTitle(context.l10n.translate('personalInformation')),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _firstNameController,
                label: context.l10n.translate('firstName'),
                hintText: 'Enter your first name',
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _lastNameController,
                label: context.l10n.translate('lastName'),
                hintText: 'Enter your last name',
                onChanged: (value) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: context.l10n.translate('email'),
                hintText: 'Enter your email',
                enabled: false, // Email нельзя изменить
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_hasChanges()) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanges() ? AppColors.purple : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _hasChanges() ? context.l10n.translate('saveChanges') : context.l10n.translate('noChanges'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          enabled: enabled,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.purple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.blue100,
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 60,
      ),
    );
  }
}
