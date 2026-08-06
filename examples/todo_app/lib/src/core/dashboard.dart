import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CubePod Showcase')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _ModuleCard(
            title: 'Core & DI',
            icon: Icons.hub,
            onTap: () => Navigator.of(context).pushNamed('/core'),
          ),
          _ModuleCard(
            title: 'Reactivity',
            icon: Icons.bolt,
            onTap: () => Navigator.of(context).pushNamed('/state'),
          ),
          _ModuleCard(
            title: 'Async & Time',
            icon: Icons.timer,
            onTap: () => Navigator.of(context).pushNamed('/async'),
          ),
          _ModuleCard(
            title: 'Network & Query',
            icon: Icons.cloud,
            onTap: () => Navigator.of(context).pushNamed('/network'),
          ),
          _ModuleCard(
            title: 'Storage & Sync',
            icon: Icons.save,
            onTap: () => Navigator.of(context).pushNamed('/storage'),
          ),
          _ModuleCard(
            title: 'Events & Resources',
            icon: Icons.alt_route,
            onTap: () => Navigator.of(context).pushNamed('/events'),
          ),
          _ModuleCard(
            title: 'Enterprise',
            icon: Icons.business,
            onTap: () => Navigator.of(context).pushNamed('/enterprise'),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
