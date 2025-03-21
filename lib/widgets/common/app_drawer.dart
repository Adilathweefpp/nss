import 'package:flutter/material.dart';
import 'package:nss_app/models/user_model.dart';

class AppDrawer extends StatelessWidget {
  final UserModel user;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<Map<String, dynamic>> menuItems;

  const AppDrawer({
    Key? key,
    required this.user,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.menuItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildDrawerItem(
              context,
              icon: item['icon'],
              title: item['title'],
              index: index,
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              user.name.substring(0, 1),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user.email,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selectedIndex == index ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selectedIndex == index ? Theme.of(context).primaryColor : null,
          fontWeight: selectedIndex == index ? FontWeight.bold : null,
        ),
      ),
      selected: selectedIndex == index,
      onTap: () {
        onItemSelected(index);
      },
    );
  }

  // Factory method to create Admin Drawer
  static AppDrawer createAdminDrawer({
    required UserModel admin,
    required int selectedIndex,
    required Function(int) onItemSelected,
  }) {
    return AppDrawer(
      user: admin,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      menuItems: const [
        {
          'icon': Icons.dashboard,
          'title': 'Dashboard',
        },
        {
          'icon': Icons.people,
          'title': 'Volunteer Management',
        },
        {
          'icon': Icons.event,
          'title': 'Event Management',
        },
        {
          'icon': Icons.admin_panel_settings,
          'title': 'Admin Management',
        },
        {
          'icon': Icons.person,
          'title': 'Profile',
        },
      ],
    );
  }

  // Factory method to create Volunteer Drawer
  static AppDrawer createVolunteerDrawer({
    required UserModel volunteer,
    required int selectedIndex,
    required Function(int) onItemSelected,
  }) {
    return AppDrawer(
      user: volunteer,
      selectedIndex: selectedIndex,
      onItemSelected: onItemSelected,
      menuItems: const [
        {
          'icon': Icons.dashboard,
          'title': 'Dashboard',
        },
        {
          'icon': Icons.event,
          'title': 'Events',
        },
        {
          'icon': Icons.how_to_reg,
          'title': 'Attendance',
        },
        {
          'icon': Icons.person,
          'title': 'Profile',
        },
      ],
    );
  }
}