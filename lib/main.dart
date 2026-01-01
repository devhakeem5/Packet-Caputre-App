import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import 'core/widgets/custom_error_widget.dart';

//التطبيق الان ناقص فيه مشكلة خصوصا مع طلبات HTTP وHTTPS حتلى اللي مو مشفرة ما بيلتقط الurl بشكل صحيح وبيعطيني بداله ip او بيعرض domain فقط في حين تطبيقات اخرى تستخدم نفس الحركة تعطي النتيجة صحيحة المشكلة الثانية الانترنت يقطع في التطبيق والمشكلة الثالثة لا يلتقط ولا يعرض الbody سواء الخاص بالrequest او الresponse قم بحل هذه المشاكل بطريقة صحيحة تضمن التقاط كل شيء وايضا اعادة النتيجة للتطبيق الذي ارسل الطلب حتى لو اضطر الامر لتغيير الية الالتقاط المهم ان تضمن نجاح الالتقاط
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          title: 'netwatch_pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
