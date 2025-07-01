import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../providers/auth_provider.dart';
import '../providers/business_idea_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPageIndex = 0;

  final List<FeatureCardData> _features = [
    FeatureCardData(
      title: 'Pomysł na firmę',
      subtitle: 'Business Idea Generator',
      description: 'Wygeneruj innowacyjny pomysł na biznes lub rozwiń swój własny',
      icon: Icons.lightbulb_outlined,
      color: AppTheme.businessIdeaColor,
      route: '/business-idea',
      isImplemented: true,
    ),
    FeatureCardData(
      title: 'Kreator logo',
      subtitle: 'Logo Generator',
      description: 'Stwórz unikalne logo które reprezentuje Twoją markę',
      icon: Icons.palette_outlined,
      color: AppTheme.logoColor,
      route: '/logo-intro',
      isImplemented: true,
    ),
    FeatureCardData(
      title: 'Kreator strony www',
      subtitle: 'Website Generator',
      description: 'Zaprojektuj responsywną stronę internetową dla biznesu',
      icon: Icons.web_outlined,
      color: AppTheme.websiteColor,
      route: '/website-intro',
      isImplemented: true,
    ),
    FeatureCardData(
      title: 'Wystawianie faktur',
      subtitle: 'Invoice Generator',
      description: 'Twórz i zarządzaj fakturami dla swoich klientów',
      icon: Icons.receipt_long_outlined,
      color: AppTheme.invoiceColor,
      route: '/invoice-intro',
      isImplemented: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFeatureTap(FeatureCardData feature) {
    print('DEBUG: Kliknięto na feature: ${feature.title}, route: ${feature.route}');
    
    // coming soon
    if (!feature.isImplemented) {
      print('DEBUG: Showing coming soon dialog');
      _showComingSoonDialog(feature.title);
      return;
    }

    if (feature.route == '/business-idea') {
      print('DEBUG: Navigating to business idea');
      _navigateToBusinessIdea();
    } else {
      print('DEBUG: Navigating to route: ${feature.route}');
      Navigator.of(context).pushNamed(feature.route);
    }
  }

  Future<void> _navigateToBusinessIdea() async {
    print('DEBUG: _navigateToBusinessIdea started');
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessIdeaProvider = Provider.of<BusinessIdeaProvider>(context, listen: false);
      
      print('DEBUG: Got providers, user: ${authProvider.user?.uid}');
      
      if (authProvider.user != null) {
        print('DEBUG: Creating new business idea...');
        final businessIdeaId = await businessIdeaProvider.createNewBusinessIdea(authProvider.user!.uid);
        print('DEBUG: Created business idea with ID: $businessIdeaId');
        
        if (mounted) {
          print('DEBUG: Navigating to /business-idea');
          Navigator.of(context).pushNamed('/business-idea');
        } else {
          print('DEBUG: Widget not mounted, skipping navigation');
        }
      } else {
        print('DEBUG: User is null');
      }
    } catch (e) {
      print('DEBUG: Error in _navigateToBusinessIdea: $e');
    }
  }

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.construction,
              color: AppTheme.invoiceColor,
            ),
            const SizedBox(width: 12),
            Text(
              'Wkrótce!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        content: Text(
          'Funkcja "$featureName" jest obecnie w rozwoju. Następne aktualizacje przyniosą jeszcze więcej możliwości!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AnimationLimiter(
              child: Column(
                children: [
                  // Header
                  AnimationConfiguration.staggeredList(
                    position: 0,
                    child: SlideAnimation(
                      verticalOffset: -30,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Witaj w FirmBox!',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Consumer<AuthProvider>(
                                      builder: (context, authProvider, child) {
                                        if (authProvider.isLoading) {
                                          return const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
                                            ),
                                          );
                                        }
                                        return Text(
                                          authProvider.user?.displayName ?? 
                                          authProvider.user?.email ?? 'Użytkowniku',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // menu
                              PopupMenuButton<String>(
                                icon: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                color: AppTheme.cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'logout') {
                                    _signOut();
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.logout,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Wyloguj się',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // title
                  AnimationConfiguration.staggeredList(
                    position: 1,
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Text(
                                'Wybierz funkcję',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              Text(
                                '${_currentPageIndex + 1}/${_features.length}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.businessIdeaColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // slider
                  Expanded(
                    child: AnimationConfiguration.staggeredList(
                      position: 2,
                      child: SlideAnimation(
                        verticalOffset: 50,
                        child: FadeInAnimation(
                          child: Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: _features.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPageIndex = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: FeatureCard(
                                        data: _features[index],
                                        onTap: () => _onFeatureTap(_features[index]),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 24),

                              SmoothPageIndicator(
                                controller: _pageController,
                                count: _features.length,
                                effect: WormEffect(
                                  dotColor: AppTheme.textHint,
                                  activeDotColor: AppTheme.businessIdeaColor,
                                  dotHeight: 8,
                                  dotWidth: 8,
                                  spacing: 12,
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class FeatureCardData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final String route;
  final bool isImplemented;

  FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    required this.isImplemented,
  });
} 