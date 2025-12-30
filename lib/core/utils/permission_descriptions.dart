import 'package:flutter/material.dart';

class PermissionDetail {
  final String nameEn;
  final String nameAr;
  final String description;
  final IconData icon;

  const PermissionDetail({
    required this.nameEn,
    required this.nameAr,
    required this.description,
    required this.icon,
  });
}

class PermissionDescriptions {
  static const Map<String, PermissionDetail> _details = {
    // CAMERA
    'android.permission.CAMERA': PermissionDetail(
      nameEn: 'Camera',
      nameAr: 'الكاميرا',
      description: 'يسمح هذا الإذن للتطبيق بالوصول إلى الكاميرا لالتقاط الصور وتسجيل الفيديوهات.',
      icon: Icons.camera_alt,
    ),

    // LOCATION
    'android.permission.ACCESS_FINE_LOCATION': PermissionDetail(
      nameEn: 'Precise Location',
      nameAr: 'الموقع الدقيق',
      description: 'يسمح للتطبيق بالوصول إلى موقعك الجغرافي الدقيق باستخدام GPS.',
      icon: Icons.my_location,
    ),
    'android.permission.ACCESS_COARSE_LOCATION': PermissionDetail(
      nameEn: 'Approximate Location',
      nameAr: 'الموقع التقريبي',
      description: 'يسمح للتطبيق بالوصول إلى موقعك التقريبي بناءً على أبراج الاتصال والواي فاي.',
      icon: Icons.location_on_outlined,
    ),
    'android.permission.ACCESS_BACKGROUND_LOCATION': PermissionDetail(
      nameEn: 'Background Location',
      nameAr: 'الموقع في الخلفية',
      description: 'يسمح للتطبيق بالوصول إلى موقعك حتى عندما لا تستخدم التطبيق.',
      icon: Icons.location_history,
    ),

    // STORAGE
    'android.permission.READ_EXTERNAL_STORAGE': PermissionDetail(
      nameEn: 'Read Storage',
      nameAr: 'قراءة التخزين',
      description: 'يسمح للتطبيق بقراءة الملفات والصور والوسائط من ذاكرة جهازك.',
      icon: Icons.folder_open,
    ),
    'android.permission.WRITE_EXTERNAL_STORAGE': PermissionDetail(
      nameEn: 'Write Storage',
      nameAr: 'تعديل التخزين',
      description: 'يسمح للتطبيق بحفظ وتعديل الملفات على ذاكرة جهازك.',
      icon: Icons.create_new_folder,
    ),
    'android.permission.MANAGE_EXTERNAL_STORAGE': PermissionDetail(
      nameEn: 'All Files Access',
      nameAr: 'إدارة كاملة للتخزين',
      description: 'يمنح التطبيق صلاحية كاملة للوصول إلى جميع الملفات وإدارتها.',
      icon: Icons.folder_special,
    ),
    'android.permission.READ_MEDIA_IMAGES': PermissionDetail(
      nameEn: 'Read Images',
      nameAr: 'قراءة الصور',
      description: 'يسمح للتطبيق بالوصول إلى الصور المخزنة على جهازك.',
      icon: Icons.image,
    ),
    'android.permission.READ_MEDIA_VIDEO': PermissionDetail(
      nameEn: 'Read Video',
      nameAr: 'قراءة الفيديو',
      description: 'يسمح للتطبيق بالوصول إلى ملفات الفيديو المخزنة على جهازك.',
      icon: Icons.videocam,
    ),
    'android.permission.READ_MEDIA_AUDIO': PermissionDetail(
      nameEn: 'Read Audio',
      nameAr: 'قراءة الصوت',
      description: 'يسمح للتطبيق بالوصول إلى الملفات الصوتية المخزنة على جهازك.',
      icon: Icons.audiotrack,
    ),

    // MICROPHONE
    'android.permission.RECORD_AUDIO': PermissionDetail(
      nameEn: 'Microphone',
      nameAr: 'الميكروفون',
      description: 'يسمح للتطبيق بتسجيل الصوت باستخدام الميكروفون.',
      icon: Icons.mic,
    ),

    // CONTACTS
    'android.permission.READ_CONTACTS': PermissionDetail(
      nameEn: 'Read Contacts',
      nameAr: 'قراءة جهات الاتصال',
      description: 'يسمح للتطبيق بالوصول إلى قائمة جهات الاتصال المسجلة في هاتفك.',
      icon: Icons.contacts,
    ),
    'android.permission.WRITE_CONTACTS': PermissionDetail(
      nameEn: 'Write Contacts',
      nameAr: 'تعديل جهات الاتصال',
      description: 'يسمح للتطبيق بإضافة أو تعديل جهات الاتصال في هاتفك.',
      icon: Icons.person_add,
    ),
    'android.permission.GET_ACCOUNTS': PermissionDetail(
      nameEn: 'Get Accounts',
      nameAr: 'الوصول للحسابات',
      description: 'يسمح للتطبيق بمعرفة الحسابات المسجلة على الجهاز (مثل Google, WhatsApp).',
      icon: Icons.account_box,
    ),

    // PHONE & CALLS
    'android.permission.READ_PHONE_STATE': PermissionDetail(
      nameEn: 'Read Phone State',
      nameAr: 'قراءة حالة الهاتف',
      description: 'يسمح للتطبيق بمعرفة رقم الهاتف وحالة الشبكة ومعرف الجهاز (IMEI).',
      icon: Icons.phone_android,
    ),
    'android.permission.CALL_PHONE': PermissionDetail(
      nameEn: 'Call Phone',
      nameAr: 'إجراء مكالمات',
      description: 'يسمح للتطبيق بإجراء مكالمات هاتفية مباشرة دون تدخلك.',
      icon: Icons.call,
    ),
    'android.permission.READ_CALL_LOG': PermissionDetail(
      nameEn: 'Read Call Log',
      nameAr: 'سجل المكالمات',
      description: 'يسمح للتطبيق بقراءة سجل المكالمات الصادرة والواردة.',
      icon: Icons.history,
    ),
    'android.permission.WRITE_CALL_LOG': PermissionDetail(
      nameEn: 'Write Call Log',
      nameAr: 'تعديل سجل المكالمات',
      description: 'يسمح للتطبيق بحذف أو تعديل سجل المكالمات.',
      icon: Icons.edit_note,
    ),
    'android.permission.ANSWER_PHONE_CALLS': PermissionDetail(
      nameEn: 'Answer Phone Calls',
      nameAr: 'الرد على المكالمات',
      description: 'يسمح للتطبيق بالرد على المكالمات الهاتفية الواردة.',
      icon: Icons.call_received,
    ),
    'android.permission.USE_SIP': PermissionDetail(
      nameEn: 'Use SIP',
      nameAr: 'استخدام SIP',
      description: 'يسمح للتطبيق بإجراء مكالمات عبر بروتوكول SIP (مكالمات الإنترنت).',
      icon: Icons.dialer_sip,
    ),
    'android.permission.PROCESS_OUTGOING_CALLS': PermissionDetail(
      nameEn: 'Process Outgoing Calls',
      nameAr: 'معالجة المكالمات الصادرة',
      description: 'يسمح ولا يتتطبيق برؤية الرقم الذي تتصل به وتعديله أو قطع الاتصال.',
      icon: Icons.phone_forwarded,
    ),

    // SMS
    'android.permission.SEND_SMS': PermissionDetail(
      nameEn: 'Send SMS',
      nameAr: 'ارسال رسائل نصية',
      description: 'يسمح للتطبيق بإرسال رسائل نصية قصيرة SMS.',
      icon: Icons.send,
    ),
    'android.permission.READ_SMS': PermissionDetail(
      nameEn: 'Read SMS',
      nameAr: 'قراءة الرسائل النصية',
      description: 'يسمح للتطبيق بقراءة رسائلك النصية الخاصة.',
      icon: Icons.sms,
    ),
    'android.permission.RECEIVE_SMS': PermissionDetail(
      nameEn: 'Receive SMS',
      nameAr: 'استلام رسائل نصية',
      description: 'يسمح للتطبيق باعتراض الرسائل النصية الواردة.',
      icon: Icons.sms_failed,
    ),
    'android.permission.RECEIVE_WAP_PUSH': PermissionDetail(
      nameEn: 'Receive WAP Push',
      nameAr: 'استلام رسائل WAP',
      description: 'يسمح للتطبيق باستلام رسائل WAP Push.',
      icon: Icons.message,
    ),
    'android.permission.RECEIVE_MMS': PermissionDetail(
      nameEn: 'Receive MMS',
      nameAr: 'استلام رسائل وسائط',
      description: 'يسمح للتطبيق باستلام رسائل الوسائط المتعددة MMS.',
      icon: Icons.mms,
    ),

    // CALENDAR
    'android.permission.READ_CALENDAR': PermissionDetail(
      nameEn: 'Read Calendar',
      nameAr: 'قراءة التقويم',
      description: 'يسمح للتطبيق بالاطلاع على الأحداث والمواعيد في تقويمك.',
      icon: Icons.calendar_today,
    ),
    'android.permission.WRITE_CALENDAR': PermissionDetail(
      nameEn: 'Write Calendar',
      nameAr: 'تعديل التقويم',
      description: 'يسمح للتطبيق بإضافة أو تعديل الأحداث في تقويمك.',
      icon: Icons.edit_calendar,
    ),

    // NETWORK & WIFI
    'android.permission.INTERNET': PermissionDetail(
      nameEn: 'Internet',
      nameAr: 'الوصول للإنترنت',
      description: 'يسمح للتطبيق بالاتصال بالإنترنت وتبادل البيانات.',
      icon: Icons.public,
    ),
    'android.permission.ACCESS_NETWORK_STATE': PermissionDetail(
      nameEn: 'Network State',
      nameAr: 'حالة الشبكة',
      description: 'يسمح للتطبيق بمعرفة ما إذا كنت متصلاً بالإنترنت ونوع الاتصال (واي فاي/بيانات).',
      icon: Icons.network_check,
    ),
    'android.permission.ACCESS_WIFI_STATE': PermissionDetail(
      nameEn: 'WiFi State',
      nameAr: 'حالة الواي فاي',
      description: 'يسمح للتطبيق بمعرفة معلومات حول شبكة الواي فاي المتصل بها.',
      icon: Icons.wifi,
    ),
    'android.permission.CHANGE_WIFI_STATE': PermissionDetail(
      nameEn: 'Change WiFi State',
      nameAr: 'تغيير حالة الواي فاي',
      description: 'يسمح للتطبيق بتشغيل أو إيقاف الواي فاي والاتصال بنقاط الوصول.',
      icon: Icons.wifi_tethering,
    ),
    'android.permission.CHANGE_NETWORK_STATE': PermissionDetail(
      nameEn: 'Change Network State',
      nameAr: 'تغيير حالة الشبكة',
      description: 'يسمح للتطبيق بتغيير حالة الاتصال بالشبكة.',
      icon: Icons.settings_ethernet,
    ),

    // BLUETOOTH
    'android.permission.BLUETOOTH': PermissionDetail(
      nameEn: 'Bluetooth',
      nameAr: 'البلوتوث',
      description: 'يسمح للتطبيق بالاتصال بالأجهزة المقترنة.',
      icon: Icons.bluetooth,
    ),
    'android.permission.BLUETOOTH_ADMIN': PermissionDetail(
      nameEn: 'Bluetooth Admin',
      nameAr: 'إدارة البلوتوث',
      description: 'يسمح للتطبيق بالبحث عن الأجهزة والاقتران بها وتعديل الإعدادات.',
      icon: Icons.bluetooth_searching,
    ),
    'android.permission.BLUETOOTH_CONNECT': PermissionDetail(
      nameEn: 'Bluetooth Connect',
      nameAr: 'اتصال بلوتوث',
      description: 'يسمح للتطبيق بالاتصال بالأجهزة القريبة عبر البلوتوث (Android 12+).',
      icon: Icons.bluetooth_connected,
    ),
    'android.permission.BLUETOOTH_SCAN': PermissionDetail(
      nameEn: 'Bluetooth Scan',
      nameAr: 'فحص بلوتوث',
      description: 'يسمح للتطبيق بالبحث عن أجهزة بلوتوث قريبة (Android 12+).',
      icon: Icons.radar,
    ),
    'android.permission.BLUETOOTH_ADVERTISE': PermissionDetail(
      nameEn: 'Bluetooth Advertise',
      nameAr: 'بث بلوتوث',
      description: 'يسمح للتطبيق بجعل جهازك مرئياً لأجهزة البلوتوث الأخرى (Android 12+).',
      icon: Icons.bluetooth_audio,
    ),

    // SENSORS & PHYSICAL ACTIVITY
    'android.permission.BODY_SENSORS': PermissionDetail(
      nameEn: 'Body Sensors',
      nameAr: 'أجهزة استشعار الجسم',
      description: 'يسمح للتطبيق بالوصول إلى بيانات المستشعرات الحيوية (مثل معدل ضربات القلب).',
      icon: Icons.monitor_heart,
    ),
    'android.permission.ACTIVITY_RECOGNITION': PermissionDetail(
      nameEn: 'Physical Activity',
      nameAr: 'النشاط البدني',
      description: 'يسمح للتطبيق بالتعرف على نشاطك الحركي (مشي، جري، ركوب سيارة).',
      icon: Icons.directions_run,
    ),

    // SYSTEM & TOOLS
    'android.permission.VIBRATE': PermissionDetail(
      nameEn: 'Vibrate',
      nameAr: 'الاهتزاز',
      description: 'يسمح للتطبيق بالتحكم في اهتزاز الهاتف.',
      icon: Icons.vibration,
    ),
    'android.permission.WAKE_LOCK': PermissionDetail(
      nameEn: 'Wake Lock',
      nameAr: 'منع السكون',
      description:
          'يسمح للتطبيق بمنع الهاتف من الدخول في وضع السكون للحفاظ على عمل الشاشة أو المعالج.',
      icon: Icons.power,
    ),
    'android.permission.FOREGROUND_SERVICE': PermissionDetail(
      nameEn: 'Foreground Service',
      nameAr: 'خدمة في الواجهة',
      description: 'يسمح للتطبيق بتشغيل خدمات تظهر إشعاراً مستمراً وتعمل في الخلفية.',
      icon: Icons.notifications_active,
    ),
    'android.permission.POST_NOTIFICATIONS': PermissionDetail(
      nameEn: 'Notifications',
      nameAr: 'الإشعارات',
      description: 'يسمح للتطبيق بإرسال إشعارات و تنبيهات لك (Android 13+).',
      icon: Icons.notifications,
    ),
    'com.android.vending.BILLING': PermissionDetail(
      nameEn: 'In-App Billing',
      nameAr: 'شراء داخل التطبيق',
      description: 'يسمح للتطبيق بإجراء عمليات شراء و دفع عبر متجر جوجل بلاي.',
      icon: Icons.shopping_cart,
    ),
    'android.permission.SYSTEM_ALERT_WINDOW': PermissionDetail(
      nameEn: 'Display Over Apps',
      nameAr: 'الظهور فوق التطبيقات',
      description: 'يسمح للتطبيق بالرسم والظهور فوق التطبيقات الأخرى (نافذة عائمة).',
      icon: Icons.layers,
    ),
    'android.permission.REQUEST_INSTALL_PACKAGES': PermissionDetail(
      nameEn: 'Install Packages',
      nameAr: 'تثبيت تطبيقات',
      description: 'يسمح للتطبيق بطلب تثبيت تطبيقات أخرى من خارج المتجر.',
      icon: Icons.system_update_alt,
    ),
    'android.permission.RECEIVE_BOOT_COMPLETED': PermissionDetail(
      nameEn: 'Run at Startup',
      nameAr: 'العمل عند التشغيل',
      description: 'يسمح للتطبيق بالعمل تلقائياً فور إعادة تشغيل الجهاز.',
      icon: Icons.restart_alt,
    ),
    'android.permission.KILL_BACKGROUND_PROCESSES': PermissionDetail(
      nameEn: 'Kill Background Processes',
      nameAr: 'إغلاق العمليات الخلفية',
      description: 'يسمح للتطبيق بإغلاق عمليات التطبيقات الأخرى التي تعمل في الخلفية.',
      icon: Icons.cancel_presentation,
    ),
    'android.permission.NFC': PermissionDetail(
      nameEn: 'NFC',
      nameAr: 'الاتصال قريب المدى (NFC)',
      description: 'يسمح للتطبيق باستخدام تقنية NFC للتواصل مع البطاقات والأجهزة القريبة.',
      icon: Icons.nfc,
    ),
    'android.permission.SET_WALLPAPER': PermissionDetail(
      nameEn: 'Set Wallpaper',
      nameAr: 'تعيين الخلفية',
      description: 'يسمح للتطبيق بتغيير خلفية الشاشة الرئيسية.',
      icon: Icons.wallpaper,
    ),
    'android.permission.SET_ALARM': PermissionDetail(
      nameEn: 'Set Alarm',
      nameAr: 'ضبط منبه',
      description: 'يسمح للتطبيق بضبط منبه في تطبيق الساعة.',
      icon: Icons.alarm_add,
    ),
    'android.permission.WRITE_SETTINGS': PermissionDetail(
      nameEn: 'Modify System Settings',
      nameAr: 'تعديل إعدادات النظام',
      description: 'يسمح للتطبيق بتغيير إعدادات النظام (مثل السطوع ومدة توقف الشاشة).',
      icon: Icons.settings_suggest,
    ),
    'android.permission.READ_SYNC_SETTINGS': PermissionDetail(
      nameEn: 'Read Sync Settings',
      nameAr: 'قراءة إعدادات المزامنة',
      description: 'يسمح للتطبيق بمعرفة ما إذا كانت المزامنة مفعلة للحسابات.',
      icon: Icons.sync,
    ),
    'android.permission.WRITE_SYNC_SETTINGS': PermissionDetail(
      nameEn: 'Write Sync Settings',
      nameAr: 'تعديل إعدادات المزامنة',
      description: 'يسمح للتطبيق بتفعيل أو تعطيل المزامنة للحسابات.',
      icon: Icons.sync_problem,
    ),
    'android.permission.AUTHENTICATE_ACCOUNTS': PermissionDetail(
      nameEn: 'Authenticate Accounts',
      nameAr: 'توثيق الحسابات',
      description: 'يسمح للتطبيق بالقيام بدور موثق الحسابات وإدارة الحسابات.',
      icon: Icons.verified,
    ),
    'android.permission.MANAGE_ACCOUNTS': PermissionDetail(
      nameEn: 'Manage Accounts',
      nameAr: 'إدارة الحسابات',
      description: 'يسمح للتطبيق بإضافة أو إزالة الحسابات من النظام.',
      icon: Icons.manage_accounts,
    ),
  };

  static PermissionDetail? get(String name) {
    return _details[name];
  }

  static PermissionDetail getOrDefault(String name) {
    if (_details.containsKey(name)) {
      return _details[name]!;
    }

    // Fallback logic
    String simplifiedName = name.split('.').last.replaceAll('_', ' ').toLowerCase();
    // Capitalize first letter
    if (simplifiedName.isNotEmpty) {
      simplifiedName = simplifiedName[0].toUpperCase() + simplifiedName.substring(1);
    }

    return PermissionDetail(
      nameEn: simplifiedName,
      nameAr: simplifiedName, // Fallback to English name if no Arabic translation
      description:
          'هذا الإذن يسمح للتطبيق بالقيام بعملية: $simplifiedName. (لا يوجد وصف تفصيلي متوفر لهذا الإذن حالياً).',
      icon: Icons.security,
    );
  }
}
