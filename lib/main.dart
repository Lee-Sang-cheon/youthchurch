import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/nickname_page.dart';
import 'features/auth/presentation/church_setup_page.dart';
import 'features/church/presentation/church_hall_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: 'af55d662743a1a77afe35158024c3aa8');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: YouthChurchApp()));
}

class YouthChurchApp extends StatelessWidget {
  const YouthChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '신앙 메타버스',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF05040A),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session;
        if (session == null) return const LoginPage();
        return const ProfileGate();
      },
    );
  }
}

// 로그인 후 닉네임 설정 여부 확인
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final _repo = UserRepository();
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repo.getMyProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data;
        if (profile == null || profile['nickname'] == '새신자') {
          return NicknamePage(
            onComplete: () => setState(() {
              _profileFuture = _repo.getMyProfile();
            }),
          );
        }
        if (profile['church_id'] == null) {
          return ChurchSetupPage(
            onComplete: () => setState(() {
              _profileFuture = _repo.getMyProfile();
            }),
          );
        }
        return const ChurchHallPage();
      },
    );
  }
}
