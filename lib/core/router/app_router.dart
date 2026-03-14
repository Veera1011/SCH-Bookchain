import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../models/book_model.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/pending_approval_screen.dart';
import '../../screens/auth/rejected_screen.dart';
import '../../screens/employee/employee_home.dart';
import '../../screens/employee/browse_books_screen.dart';
import '../../screens/employee/book_details_screen.dart';
import '../../screens/employee/employee_discovery_screen.dart';
import '../../screens/admin/admin_inventory_overview_screen.dart';
import '../../screens/employee/borrow_book_screen.dart';
import '../../screens/employee/my_books_screen.dart';
import '../../screens/employee/return_book_screen.dart';
import '../../screens/employee/profile_screen.dart';
import '../../screens/admin/admin_home.dart';
import '../../screens/admin/analytics_screen.dart';
import '../../screens/admin/manage_books_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/all_borrows_screen.dart';
import '../../screens/admin/add_book_screen.dart';
import '../../screens/admin/user_detail_screen.dart';
import '../../screens/admin/theme_settings_screen.dart';
import '../../screens/admin/manage_locations_screen.dart';
import '../../screens/shared/notifications_screen.dart';
import '../../screens/shared/qr_scanner_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(currentProfileProvider);
  final currentProfile = profileAsync.value;

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isAuthRoute = state.uri.path == '/login' || 
                         state.uri.path == '/register' || 
                         state.uri.path == '/forgot-password' ||
                         state.uri.path == '/welcome';
      final isAuthenticated = authState.value?.session != null;
      final isProfileLoading = profileAsync.isLoading;
      
      if (!isAuthenticated && !isAuthRoute) {
        return '/welcome';
      }

      // If they just authenticated but profile hasn't loaded yet from Supabase, stay where we are (let it load)
      if (isAuthenticated && isProfileLoading) {
        // Show a loading screen or just return null to wait on the current page
        return null; 
      }
      
      // If we are authenticated, but the DB request finished and returned NO profile (corrupted user)
      if (isAuthenticated && !isProfileLoading && currentProfile == null && !isAuthRoute) {
         return '/welcome';
      }

      if (isAuthenticated && currentProfile != null) {
        if (currentProfile.isPending && state.uri.path != '/pending-approval') {
          return '/pending-approval';
        }
        
        if (currentProfile.isRejected && state.uri.path != '/rejected') {
          return '/rejected';
        }

        if (currentProfile.isActive && (isAuthRoute || state.uri.path == '/pending-approval' || state.uri.path == '/rejected' || state.uri.path == '/welcome')) {
          if (currentProfile.isAdmin) {
            return '/admin';
          }
          return '/home';
        }
        
        if (currentProfile.isActive && state.uri.path.startsWith('/admin') && !currentProfile.isAdmin) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/rejected',
        builder: (context, state) => const RejectedScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/book-details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookDetailsScreen(bookId: id);
        },
      ),
      GoRoute(
        path: '/borrow/:bookId',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return BorrowBookScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/return/:recordId',
        builder: (context, state) {
          final recordId = state.pathParameters['recordId']!;
          return ReturnBookScreen(recordId: recordId);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => EmployeeHome(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const EmployeeDiscoveryScreen(),
          ),
          GoRoute(
            path: '/browse',
            builder: (context, state) => const BrowseBooksScreen(),
          ),
          GoRoute(
            path: '/my-books',
            builder: (context, state) => const MyBooksScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminHome(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/discovery',
            builder: (context, state) => const AdminInventoryOverviewScreen(),
          ),
          GoRoute(
            path: '/admin/books',
            builder: (context, state) => const ManageBooksScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const ManageUsersScreen(),
          ),
          GoRoute(
            path: '/admin/borrows',
            builder: (context, state) => const AllBorrowsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/admin/books/add',
        builder: (context, state) => AddBookScreen(book: state.extra as BookModel?),
      ),
      GoRoute(
        path: '/admin/theme',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/locations',
        builder: (context, state) => const ManageLocationsScreen(),
      ),
      GoRoute(
        path: '/admin/users/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return UserDetailScreen(userId: userId);
        },
      ),
    ],
  );
});
