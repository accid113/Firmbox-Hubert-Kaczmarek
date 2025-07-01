import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/business_idea_provider.dart';
import 'providers/logo_provider.dart';
import 'providers/website_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/seller_profile_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/business_idea/business_idea_intro_screen.dart';
import 'screens/business_idea/business_idea_input_screen.dart';
import 'screens/business_idea/company_name_screen.dart';
import 'screens/business_idea/competitor_analysis_screen.dart';
import 'screens/business_idea/business_plan_screen.dart';
import 'screens/business_idea/marketing_plan_screen.dart';
import 'screens/business_idea/final_screen.dart';
import 'screens/logo/logo_intro_screen.dart';
import 'screens/logo/logo_company_name_screen.dart';
import 'screens/logo/logo_business_description_screen.dart';
import 'screens/logo/logo_colors_screen.dart';
import 'screens/logo/logo_style_screen.dart';
import 'screens/logo/logo_final_screen.dart';
import 'screens/website/website_intro_screen.dart';
import 'screens/website/website_company_data_screen.dart';
import 'screens/website/website_sections_screen.dart';
import 'screens/website/website_style_screen.dart';
import 'screens/website/website_colors_screen.dart';
import 'screens/website/website_final_screen.dart';
import 'screens/invoice/invoice_intro_screen.dart';
import 'screens/invoice/invoice_seller_data_screen.dart';
import 'screens/invoice/invoice_buyer_data_screen.dart';
import 'screens/invoice/invoice_items_screen.dart';
import 'screens/invoice/invoice_summary_screen.dart';
import 'screens/invoice/invoice_final_screen.dart';
import 'screens/invoice/invoice_list_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // app check
  if (kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('6Ldg-FUrAAAAAFrdkqfOejK13RomvWH6Jr2xrIl_'),
    );
  } else {
    await FirebaseAppCheck.instance.activate();
  }

  // env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Błąd wczytywania pliku .env: $e');
  }

  runApp(const FirmBoxApp());
}

class FirmBoxApp extends StatelessWidget {
  const FirmBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusinessIdeaProvider()),
        ChangeNotifierProvider(create: (_) => LogoProvider()),
        ChangeNotifierProvider(create: (_) => WebsiteProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => SellerProfileProvider()),
      ],
      child: MaterialApp(
        title: 'FirmBox',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/business-idea': (context) => const BusinessIdeaIntroScreen(),
          '/business-idea-input': (context) => const BusinessIdeaInputScreen(),
          '/company-name': (context) => const CompanyNameScreen(),
          '/competitor-analysis': (context) => const CompetitorAnalysisScreen(),
          '/business-plan': (context) => const BusinessPlanScreen(),
          '/marketing-plan': (context) => const MarketingPlanScreen(),
          '/final': (context) => const FinalScreen(),
          '/final-screen': (context) => const FinalScreen(),
          '/logo-intro': (context) => const LogoIntroScreen(),
          '/logo-company-name': (context) => const LogoCompanyNameScreen(),
          '/logo-business-description': (context) => const LogoBusinessDescriptionScreen(),
          '/logo-colors': (context) => const LogoColorsScreen(),
          '/logo-style': (context) => const LogoStyleScreen(),
          '/logo-final': (context) => const LogoFinalScreen(),
          '/website-intro': (context) => const WebsiteIntroScreen(),
          '/website-company-data': (context) => const WebsiteCompanyDataScreen(),
          '/website-sections': (context) => const WebsiteSectionsScreen(),
          '/website-style': (context) => const WebsiteStyleScreen(),
          '/website-colors': (context) => const WebsiteColorsScreen(),
          '/website-final': (context) => const WebsiteFinalScreen(),
          '/invoice-intro': (context) => const InvoiceIntroScreen(),
          '/invoice-seller-data': (context) => const InvoiceSellerDataScreen(),
          '/invoice-buyer-data': (context) => const InvoiceBuyerDataScreen(),
          '/invoice-items': (context) => const InvoiceItemsScreen(),
          '/invoice-summary': (context) => const InvoiceSummaryScreen(),
          '/invoice-final': (context) => const InvoiceFinalScreen(),
          '/invoice-list': (context) => const InvoiceListScreen(),
        },
      ),
    );
  }
}
