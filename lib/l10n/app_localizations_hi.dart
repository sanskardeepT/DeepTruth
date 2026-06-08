// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'DeepTruth';

  @override
  String get tagline => 'सच्चाई देखें';

  @override
  String get factCheckTitle => 'ट्रूथ लेंस';

  @override
  String get factCheckHint => 'खबर, दावा, लिंक या रील URL पेस्ट करें...';

  @override
  String get analyzeButton => 'विश्लेषण करें';

  @override
  String get analyzing => 'विश्लेषण हो रहा है...';

  @override
  String get verdictTrue => 'सच';

  @override
  String get verdictFalse => 'झूठ';

  @override
  String get verdictMisleading => 'भ्रामक';

  @override
  String get verdictUnverified => 'अज्ञात';

  @override
  String get truthScore => 'सत्य स्कोर';

  @override
  String get manipulationScore => 'हेरफेर स्कोर';

  @override
  String get missingContext => 'छूटा हुआ संदर्भ';

  @override
  String get sources => 'स्रोत';

  @override
  String get manipulationTactics => 'हेरफेर की रणनीतियाँ';

  @override
  String get personalImpact => 'आप पर असर';

  @override
  String get downloadReport => 'रिपोर्ट डाउनलोड करें';

  @override
  String get shareReport => 'रिपोर्ट शेयर करें';

  @override
  String get trustFeed => 'ट्रस्ट फ़ीड';

  @override
  String get reelIQ => 'रील IQ';

  @override
  String get traceIQ => 'ट्रेस IQ';

  @override
  String get askIQ => 'आस्क IQ';

  @override
  String get streak => 'स्ट्रीक';

  @override
  String get home => 'होम';

  @override
  String streakDays(int count) {
    return '$count दिन की स्ट्रीक';
  }

  @override
  String get rank => 'रैंक';

  @override
  String nextRank(int days) {
    return '$days दिनों में अगला रैंक';
  }

  @override
  String get emailCheck => 'ईमेल उल्लंघन जांच';

  @override
  String get phoneCheck => 'फोन लुकअप';

  @override
  String get usernameCheck => 'यूज़रनेम खोज';

  @override
  String get websiteCheck => 'वेबसाइट WHOIS';

  @override
  String get ipCheck => 'IP लुकअप';

  @override
  String get imageSearch => 'रिवर्स इमेज सर्च';

  @override
  String get osintDisclaimer => 'केवल सार्वजनिक स्रोतों से डेटा। परिणाम अधूरे हो सकते हैं।';

  @override
  String get investigateYourself => 'पहले खुद को जांचें';

  @override
  String get typeMessage => 'कुछ भी पूछें...';

  @override
  String get sources2 => 'स्रोत';

  @override
  String get relatedFacts => 'संबंधित तथ्य';

  @override
  String get noInternet => 'कनेक्शन नहीं है';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'कुछ गलत हुआ';

  @override
  String get errorRetry => 'कुछ गलत हुआ। नीचे खींचें।';

  @override
  String get dailyReality => 'आज की रियलिटी चेक';

  @override
  String get trendingChecks => 'ट्रेंडिंग चेक्स';

  @override
  String get quickActions => 'त्वरित क्रियाएं';

  @override
  String get checkNews => 'खबर चेक करें';

  @override
  String get checkReel => 'रील/वीडियो चेक करें';

  @override
  String get checkWebsite => 'वेबसाइट सत्यापित करें';

  @override
  String get reportId => 'रिपोर्ट ID';

  @override
  String get generatedBy => 'DeepTruth द्वारा निर्मित';

  @override
  String get dataOnly => 'केवल डेटा। निष्कर्ष आपका अपना।';

  @override
  String get scanToVerify => 'इस रिपोर्ट की प्रामाणिकता सत्यापित करने के लिए स्कैन करें';

  @override
  String osintRateLimit(int limit) {
    return 'दैनिक सीमा पहुंच गई ($limit लुकअप/दिन)। कल रीसेट होगा।';
  }

  @override
  String get analysisUnavailable => 'विश्लेषण अस्थायी रूप से अनुपलब्ध है। पुनः प्रयास करें।';

  @override
  String get offlineMode => 'ऑफलाइन — कैश डेटा दिख रहा है';

  @override
  String get leaderboard => 'लीडरबोर्ड';

  @override
  String get globalRanking => 'वैश्विक रैंकिंग';

  @override
  String get streakFreezeUsed => 'इस महीने स्ट्रीक फ्रीज़ इस्तेमाल हो गया';

  @override
  String get streakFreeze => 'स्ट्रीक फ्रीज़ का उपयोग करें';

  @override
  String get achievements => 'उपलब्धियां';
}
