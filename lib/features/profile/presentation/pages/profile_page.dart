import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:beer_store_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:beer_store_app/features/cart/presentation/providers/cart_provider.dart';
import 'package:beer_store_app/core/theme/theme_provider.dart';
import 'package:beer_store_app/core/services/fcm_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFcmToken();
  }

  Future<void> _loadFcmToken() async {
    final token = await FcmService.instance.getToken();
    if (mounted) setState(() => _fcmToken = token);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    context.read<CartProvider>().clearCart();
    await context.read<AuthProvider>().logout();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.firebaseUser;
    final themeProvider = context.watch<ThemeProvider>();

    final displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Pengguna';
    final email = user?.email ?? '-';
    final photoUrl = user?.photoURL;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar + nama
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: photoUrl == null
                    ? Text(
                        displayName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Info akun
        _SectionCard(
          children: [
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email,
            ),
            const Divider(height: 1),
            _InfoTile(
              icon: Icons.verified_user_outlined,
              label: 'Status Email',
              value: user?.emailVerified == true
                  ? 'Terverifikasi'
                  : 'Belum Terverifikasi',
              valueColor: user?.emailVerified == true
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Preferensi
        _SectionCard(
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Mode Gelap'),
              trailing: Switch(
                value: themeProvider.isDark,
                onChanged: (_) => themeProvider.toggle(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // FCM token (untuk debugging)
        if (_fcmToken != null)
          _SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token (debug)',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _fcmToken!,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(color: valueColor),
      ),
    );
  }
}
