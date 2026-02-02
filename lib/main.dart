import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait for field use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI style for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.primaryDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const VibrationAnalyzerApp());
}

class VibrationAnalyzerApp extends StatelessWidget {
  const VibrationAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Vibration Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    _animationController.forward();
    
    // Initialize app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }
  
  Future<void> _initializeApp() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.initialize();
    
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentBlue.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.vibration,
                        size: 64,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App name
                    const Text(
                      'Vibration Analyzer',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Predictive Maintenance Tool',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<AppProvider>(
                      builder: (context, provider, child) {
                        String status = 'Initializing...';
                        if (provider.isInitialized) {
                          status = 'Ready';
                        } else if (provider.error != null) {
                          status = 'Error: ${provider.error}';
                        }
                        return Text(
                          status,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
