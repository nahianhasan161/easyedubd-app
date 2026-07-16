import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  // Social / contact links — update these with the real Easy Education BD handles.
  static const String whatsappNumber = '+8801628424161'; // e.g. 88017XXXXXXXX
  static const String facebookUrl =
      'https://www.facebook.com/EasyEducationForU';
  static const String youtubeUrl =
      'https://www.youtube.com/@EasyEducationBangladesh';
  static const String phoneNumber = '+8801628424161';
  static const String email = 'easyeducationbd.info@gmail.com';

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = [
      _ContactItem(
        icon: Icons.whatshot_rounded,
        color: const Color(0xFF25D366),
        label: 'WhatsApp',
        subtitle: 'Chat with our support team',
        onTap: () => _launch('https://wa.me/$whatsappNumber'),
      ),
      _ContactItem(
        icon: Icons.facebook_rounded,
        color: const Color(0xFF1877F2),
        label: 'Facebook',
        subtitle: 'Follow us on Facebook',
        onTap: () => _launch(facebookUrl),
      ),
      _ContactItem(
        icon: Icons.play_circle_fill_rounded,
        color: const Color(0xFFFF0000),
        label: 'YouTube',
        subtitle: 'Watch lessons & updates',
        onTap: () => _launch(youtubeUrl),
      ),
      _ContactItem(
        icon: Icons.phone_rounded,
        color: Colors.green,
        label: 'Phone',
        subtitle: phoneNumber,
        onTap: () => _launch('tel:$phoneNumber'),
      ),
      _ContactItem(
        icon: Icons.email_rounded,
        color: theme.colorScheme.primary,
        label: 'Email',
        subtitle: email,
        onTap: () => _launch('mailto:$email'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.contact_support,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'We\'re here to help',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reach us through any of the channels below.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.color.withValues(alpha: 0.12),
                  child: Icon(item.icon, color: item.color),
                ),
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: item.onTap,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _ContactItem {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}
