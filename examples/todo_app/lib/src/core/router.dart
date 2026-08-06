import 'package:cubepod_router/cubepod_router.dart';
import 'dashboard.dart';
import '../modules/core_showcase.dart';
import '../modules/state_showcase.dart';
import '../modules/async_showcase.dart';
import '../modules/network_showcase.dart';
import '../modules/storage_showcase.dart';
import '../modules/events_showcase.dart';
import '../modules/enterprise_showcase.dart';

final showcaseRouter = CubeRouter([
  CubeRoute(
    path: '/',
    builder: (context) => const DashboardPage(),
  ),
  CubeRoute(
    path: '/core',
    builder: (context) => const CoreShowcasePage(),
  ),
  CubeRoute(
    path: '/state',
    builder: (context) => const StateShowcasePage(),
  ),
  CubeRoute(
    path: '/async',
    builder: (context) => const AsyncShowcasePage(),
  ),
  CubeRoute(
    path: '/network',
    builder: (context) => const NetworkShowcasePage(),
  ),
  CubeRoute(
    path: '/storage',
    builder: (context) => const StorageShowcasePage(),
  ),
  CubeRoute(
    path: '/events',
    builder: (context) => const EventsShowcasePage(),
  ),
  CubeRoute(
    path: '/enterprise',
    builder: (context) => const EnterpriseShowcasePage(),
  ),
]);
