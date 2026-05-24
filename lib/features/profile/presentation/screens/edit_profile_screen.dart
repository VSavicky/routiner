import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:routiner/core/constants/app_colors.dart';
import 'package:routiner/l10n/app_localizations.dart';

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
  String _originalEmail = '';

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
            _originalEmail = user.email ?? '';
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
    final currentEmail = _emailController.text.trim();
    
    return currentFirstName != _originalFirstName || 
           currentLastName != _originalLastName ||
           currentEmail != _originalEmail ||
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
              SnackBar(
                content: Text(context.l10n.translate('selectedFileDoesNotExist')),
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
      print('[EDIT PROFILE] Starting avatar conversion for user: $userId');
      
      // Проверяем что файл существует и читаем его
      if (!await imageFile.exists()) {
        print('[EDIT PROFILE ERROR] Image file does not exist: ${imageFile.path}');
        throw Exception('Image file does not exist');
      }
      
      // Читаем файл как bytes
      final fileBytes = await imageFile.readAsBytes();
      print('[EDIT PROFILE] Image file size: ${fileBytes.length} bytes');
      
      // Ограничиваем размер до 500KB для Firestore (максимум 1MB на документ)
      // base64 увеличивает размер примерно на 33%, поэтому 500KB * 1.33 = ~665KB
      if (fileBytes.length > 500 * 1024) {
        print('[EDIT PROFILE] Image too large: ${fileBytes.length} bytes. Max 500KB');
        throw Exception('Image too large. Please select an image smaller than 500KB');
      }
      
      // Конвертируем в base64
      final base64Image = base64Encode(fileBytes);
      print('[EDIT PROFILE] Base64 image length: ${base64Image.length} characters');
      
      // Создаём data URL для изображения
      final mimeType = 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Image';
      
      print('[EDIT PROFILE] Avatar converted to base64 successfully');
      return dataUrl;
    } catch (e, stackTrace) {
      print('[EDIT PROFILE ERROR] Failed to convert avatar: $e');
      print('[EDIT PROFILE ERROR] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[EDIT PROFILE ERROR] No user logged in');
        throw Exception('No user logged in');
      }

      print('[EDIT PROFILE] Saving profile for user: ${user.uid}');
      print('[EDIT PROFILE] Has avatar file: ${_avatarFile != null}');
      print('[EDIT PROFILE] Original avatar URL: $_originalAvatarUrl');
      print('[EDIT PROFILE] New avatar URL: $_avatarUrl');

      // Сначала загружаем аватар если он выбран
      String? newAvatarUrl = _avatarUrl;
      if (_avatarFile != null) {
        print('[EDIT PROFILE] Uploading new avatar...');
        try {
          newAvatarUrl = await _uploadAvatarToStorage(_avatarFile!, user.uid);
          if (newAvatarUrl == null) {
            throw Exception('Failed to upload avatar - returned null URL');
          }
          print('[EDIT PROFILE] Avatar uploaded successfully: $newAvatarUrl');
        } catch (uploadError) {
          print('[EDIT PROFILE ERROR] Avatar upload failed: $uploadError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload avatar: $uploadError'),
                backgroundColor: AppColors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          throw uploadError;
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
        print('[EDIT PROFILE] Avatar URL will be updated to: $newAvatarUrl');
      } else {
        print('[EDIT PROFILE] Avatar URL unchanged');
      }

      // Обновляем email если он изменился
      final currentEmail = _emailController.text.trim();
      if (currentEmail != _originalEmail) {
        print('[EDIT PROFILE] Email changed from $_originalEmail to $currentEmail');
        updateData['email'] = currentEmail;
        print('[EDIT PROFILE] Email will be updated in Firestore to: $currentEmail');
        // Примечание: для обновления email в Firebase Auth требуется верификация
        // await user.verifyBeforeUpdateEmail(currentEmail);
      } else {
        print('[EDIT PROFILE] Email unchanged');
      }
              
      print('[EDIT PROFILE] Updating Firestore with data: $updateData');
      
      // Используем set с merge чтобы создать документ если его нет
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      print('[EDIT PROFILE] Firestore updated/created successfully');

      // Обновляем displayName в Firebase Auth
      await user.updateDisplayName(updateData['displayName']);
      print('[EDIT PROFILE] Auth displayName updated successfully');

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
          print('[EDIT PROFILE] Closing screen and returning true');
          Navigator.pop(context, true);
        }
      }
    } on FirebaseException catch (e) {
      print('[EDIT PROFILE ERROR] Firestore error: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMessage = 'Firestore error: ${e.code}';
        if (e.code == 'permission-denied') {
          errorMessage = 'Permission denied. Please check your Firebase Firestore rules.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[EDIT PROFILE ERROR] Failed to update profile: $e');
      print('[EDIT PROFILE ERROR] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        print('[EDIT PROFILE] Loading state set to false');
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
                            : _buildAvatar(_avatarUrl),
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
                enabled: true, // Email можно изменить
                onChanged: (value) => setState(() {}),
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
  
  /// Вспомогательный метод для отображения аватара (поддерживает base64 и network URL)
  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return _buildDefaultAvatar();
    }
    
    // Проверяем если это base64 data URL
    if (avatarUrl.startsWith('data:image')) {
      try {
        // Извлекаем base64 часть из data URL
        final commaIndex = avatarUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64String = avatarUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);
          
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          );
        }
      } catch (e) {
        print('[EDIT PROFILE ERROR] Failed to decode base64 avatar: $e');
      }
      return _buildDefaultAvatar();
    }
    
    // Иначе используем network URL
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
    );
  }
}
