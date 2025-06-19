import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../controllers/auth_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';
import '../../widgets/user_avatar.dart';
import '../../services/pocketbase_service.dart';
import '../../providers/user_stats_provider.dart';

@RoutePage()
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isUsernameChanged = false;
  bool _isImageChanged = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Load current user data
    _loadUserData();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Listen to username changes
    _usernameController.addListener(() {
      final authState = ref.read(authControllerProvider);
      final userData = authState.user?.data;
      String currentUsername = '';
      
      if (userData != null) {
        // Get current username using same logic as _loadUserData
        if (userData['username'] != null && userData['username'].toString().isNotEmpty) {
          currentUsername = userData['username'].toString();
        } else if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
          currentUsername = userData['name'].toString();
        } else if (userData['email'] != null) {
          final email = userData['email'].toString();
          currentUsername = email.split('@').first;
        }
      }
      
      setState(() {
        _isUsernameChanged = _usernameController.text.trim() != currentUsername;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authState = ref.read(authControllerProvider);
    if (authState.user != null) {
      // Try to get username from different possible fields
      final userData = authState.user!.data;
      String username = '';
      
      // Check for username field first, then name, then email prefix
      if (userData['username'] != null && userData['username'].toString().isNotEmpty) {
        username = userData['username'].toString();
      } else if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
        username = userData['name'].toString();
      } else if (userData['email'] != null) {
        // Use email prefix as fallback
        final email = userData['email'].toString();
        username = email.split('@').first;
      }
      
      _usernameController.text = username;
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isImageChanged = true;
        });
        
        // Show preview with animation
        _showImagePreview();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                          Text(
                'New Profile Picture',
              style: FontUsageGuide.modalTitle,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _selectedImage!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _isImageChanged = false;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: FontUsageGuide.modalButton.copyWith(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Keep',
                        style: FontUsageGuide.modalButton,
                      ),
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isUsernameChanged && !_isImageChanged) {
      _showInfoSnackBar('No changes to save');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = ref.read(authControllerProvider.notifier);
      
      // Update profile
      await authController.updateProfile(
        username: _isUsernameChanged ? _usernameController.text.trim() : null,
        profileImage: _isImageChanged ? _selectedImage : null,
      );
      
      _showSuccessSnackBar('Profile updated successfully!');
      
      // Refresh user stats after profile update
      ref.invalidate(userStatsProvider);
      
      // Reset change flags
      setState(() {
        _isUsernameChanged = false;
        _isImageChanged = false;
        _selectedImage = null;
      });
      
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: FontUsageGuide.authButtonText.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: FontUsageGuide.authFieldLabel.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: FontUsageGuide.authButtonText.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final hasChanges = _isUsernameChanged || _isImageChanged;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(hasChanges),
                
                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // Profile Picture Section
                              _buildProfilePictureSection(user),
                              
                              const SizedBox(height: 40),
                              
                              // Account Info Card
                              _buildAccountInfoCard(user),
                              
                              const SizedBox(height: 30),
                              
                              // Username Section
                              _buildUsernameSection(),
                              
                              const SizedBox(height: 40),
                              
                              // Profile Stats
                              _buildProfileStats(),
                              
                              const SizedBox(height: 40),
                              
                              // Save Button
                              _buildSaveButton(hasChanges),
                              
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(bool hasChanges) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.router.maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Edit Profile',
            style: FontUsageGuide.appBarTitle,
          ),
          const Spacer(),
          if (hasChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unsaved',
                    style: FontUsageGuide.navigationLabel.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection(user) {
    final pocketBaseUrl = ref.watch(authControllerProvider).user != null
        ? PocketBaseService().pb.baseUrl
        : null;

    return Column(
      children: [
        Text(
          'Profile Picture',
          style: FontUsageGuide.homeSectionHeader,
        ),
        const SizedBox(height: 20),
        
        // Profile picture
        Stack(
          children: [
            // Profile picture
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : UserAvatar(
                          user: user,
                          baseUrl: pocketBaseUrl,
                          size: 120,
                          iconSize: 60,
                        ),
                ),
              ),
            ),
            
            // Edit button
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Tap to change your profile picture',
          style: FontUsageGuide.listMetadata.copyWith(color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard(user) {
    final email = user?.data['email'] ?? 'No email';
    final joinDate = user?.created != null 
        ? DateTime.parse(user!.created).year.toString()
        : 'Unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Information',
                style: FontUsageGuide.modalTitle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildInfoRow(Icons.email_outlined, 'Email', email),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, 'Member since', joinDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey.shade400,
          size: 20,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: FontUsageGuide.listMetadata.copyWith(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: FontUsageGuide.authFieldLabel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsernameSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isUsernameChanged 
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Username',
                style: FontUsageGuide.modalTitle,
              ),
              const Spacer(),
              if (_isUsernameChanged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:                   Text(
                    'Modified',
                    style: FontUsageGuide.navigationLabel.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            style: FontUsageGuide.authButtonText,
            decoration: InputDecoration(
              hintText: 'Enter your username',
                              hintStyle: FontUsageGuide.authButtonText.copyWith(color: Colors.grey.shade500),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.grey.shade400,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 12),
          
                      Text(
            'Choose a unique username that represents you',
            style: FontUsageGuide.listMetadata.copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Activity',
                style: FontUsageGuide.modalTitle,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Use Consumer to watch userStatsProvider
          Consumer(
            builder: (context, ref, child) {
              final userStatsAsync = ref.watch(userStatsProvider);
              
              return userStatsAsync.when(
                data: (userStats) {
                  if (userStats == null) {
                    return _buildDefaultStats();
                  }
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.music_note,
                              label: 'Songs Played',
                              value: userStats.songsPlayed.toString(),
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.playlist_play,
                              label: 'Playlists',
                              value: userStats.playlistsCount.toString(),
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                                                     Expanded(
                             child: _buildStatItem(
                               icon: Icons.favorite,
                               label: 'Saved Album',
                               value: userStats.likedSongs.toString(),
                               color: Colors.red,
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: _buildStatItem(
                               icon: Icons.people,
                               label: 'Saved Artist',
                               value: userStats.following.toString(),
                               color: Colors.purple,
                             ),
                           ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => _buildLoadingStats(),
                error: (error, stack) => _buildDefaultStats(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.music_note,
                label: 'Songs Played',
                value: '0',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                icon: Icons.playlist_play,
                label: 'Playlists',
                value: '0',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
                         Expanded(
               child: _buildStatItem(
                 icon: Icons.favorite,
                 label: 'Saved Album',
                 value: '0',
                 color: Colors.red,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildStatItem(
                 icon: Icons.people,
                 label: 'Saved Artist',
                 value: '0',
                 color: Colors.purple,
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.music_note,
                label: 'Songs Played',
                value: '...',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                icon: Icons.playlist_play,
                label: 'Playlists',
                value: '...',
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
                         Expanded(
               child: _buildStatItem(
                 icon: Icons.favorite,
                 label: 'Saved Album',
                 value: '...',
                 color: Colors.red,
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildStatItem(
                 icon: Icons.people,
                 label: 'Saved Artist',
                 value: '...',
                 color: Colors.purple,
               ),
             ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: FontUsageGuide.homeSectionHeader,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FontUsageGuide.listMetadata.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool hasChanges) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: hasChanges
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: hasChanges ? null : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(28),
          boxShadow: hasChanges
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasChanges && !_isLoading ? _saveChanges : null,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Icon(
                      hasChanges ? Icons.save : Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isLoading
                        ? 'Saving...'
                        : hasChanges
                            ? 'Save Changes'
                            : 'No Changes',
                    style: FontUsageGuide.authButtonText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
