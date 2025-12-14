import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class RoleTabs extends StatelessWidget {
  final UserRole selectedRole;
  final Function(UserRole) onRoleChanged;

  const RoleTabs({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFECECF0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              role: UserRole.passenger,
              label: 'Pasażer',
              icon: Icons.people,
            ),
          ),
          Expanded(
            child: _buildTab(
              role: UserRole.driver,
              label: 'Kierowca',
              icon: Icons.directions_car,
            ),
          ),
          Expanded(
            child: _buildTab(
              role: UserRole.simulation,
              label: 'Symulacja (DEV)',
              icon: Icons.science,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedRole == role;
    
    return GestureDetector(
      onTap: () => onRoleChanged(role),
      child: Container(
        margin: const EdgeInsets.all(3.5),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF0A0A0A),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A),
                  letterSpacing: -0.15,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

