import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// The application name
  ///
  /// In en, this message translates to:
  /// **'DeepTruth'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'In a world of lies, let DeepTruth be your eyes.'**
  String get tagline;

  /// No description provided for @factCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Truth Lens'**
  String get factCheckTitle;

  /// No description provided for @factCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Paste news, claim, link, or reel URL...'**
  String get factCheckHint;

  /// No description provided for @analyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyzeButton;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @verdictTrue.
  ///
  /// In en, this message translates to:
  /// **'TRUE'**
  String get verdictTrue;

  /// No description provided for @verdictFalse.
  ///
  /// In en, this message translates to:
  /// **'FALSE'**
  String get verdictFalse;

  /// No description provided for @verdictMisleading.
  ///
  /// In en, this message translates to:
  /// **'MISLEADING'**
  String get verdictMisleading;

  /// No description provided for @verdictUnverified.
  ///
  /// In en, this message translates to:
  /// **'UNVERIFIED'**
  String get verdictUnverified;

  /// No description provided for @truthScore.
  ///
  /// In en, this message translates to:
  /// **'Truth Score'**
  String get truthScore;

  /// No description provided for @manipulationScore.
  ///
  /// In en, this message translates to:
  /// **'Manipulation Score'**
  String get manipulationScore;

  /// No description provided for @missingContext.
  ///
  /// In en, this message translates to:
  /// **'Missing Context'**
  String get missingContext;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @manipulationTactics.
  ///
  /// In en, this message translates to:
  /// **'Manipulation Tactics'**
  String get manipulationTactics;

  /// No description provided for @personalImpact.
  ///
  /// In en, this message translates to:
  /// **'Personal Impact'**
  String get personalImpact;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get shareReport;

  /// No description provided for @trustFeed.
  ///
  /// In en, this message translates to:
  /// **'Trust Feed'**
  String get trustFeed;

  /// No description provided for @reelIQ.
  ///
  /// In en, this message translates to:
  /// **'ReelIQ'**
  String get reelIQ;

  /// No description provided for @traceIQ.
  ///
  /// In en, this message translates to:
  /// **'TraceIQ'**
  String get traceIQ;

  /// No description provided for @askIQ.
  ///
  /// In en, this message translates to:
  /// **'AskIQ'**
  String get askIQ;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String streakDays(int count);

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @nextRank.
  ///
  /// In en, this message translates to:
  /// **'Next rank in {days} days'**
  String nextRank(int days);

  /// No description provided for @emailCheck.
  ///
  /// In en, this message translates to:
  /// **'Email Breach Check'**
  String get emailCheck;

  /// No description provided for @phoneCheck.
  ///
  /// In en, this message translates to:
  /// **'Phone Lookup'**
  String get phoneCheck;

  /// No description provided for @usernameCheck.
  ///
  /// In en, this message translates to:
  /// **'Username Search'**
  String get usernameCheck;

  /// No description provided for @websiteCheck.
  ///
  /// In en, this message translates to:
  /// **'Website WHOIS'**
  String get websiteCheck;

  /// No description provided for @ipCheck.
  ///
  /// In en, this message translates to:
  /// **'IP Lookup'**
  String get ipCheck;

  /// No description provided for @imageSearch.
  ///
  /// In en, this message translates to:
  /// **'Reverse Image Search'**
  String get imageSearch;

  /// No description provided for @osintDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Data from public sources only. Results may be incomplete.'**
  String get osintDisclaimer;

  /// No description provided for @investigateYourself.
  ///
  /// In en, this message translates to:
  /// **'Investigate Yourself First'**
  String get investigateYourself;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get typeMessage;

  /// No description provided for @sources2.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources2;

  /// No description provided for @relatedFacts.
  ///
  /// In en, this message translates to:
  /// **'Related Facts'**
  String get relatedFacts;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Pull to refresh.'**
  String get errorRetry;

  /// No description provided for @dailyReality.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reality Check'**
  String get dailyReality;

  /// No description provided for @trendingChecks.
  ///
  /// In en, this message translates to:
  /// **'Trending Checks'**
  String get trendingChecks;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @checkNews.
  ///
  /// In en, this message translates to:
  /// **'Check a news article'**
  String get checkNews;

  /// No description provided for @checkReel.
  ///
  /// In en, this message translates to:
  /// **'Check a reel/video'**
  String get checkReel;

  /// No description provided for @checkWebsite.
  ///
  /// In en, this message translates to:
  /// **'Verify a website'**
  String get checkWebsite;

  /// No description provided for @reportId.
  ///
  /// In en, this message translates to:
  /// **'Report ID'**
  String get reportId;

  /// No description provided for @generatedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by DeepTruth'**
  String get generatedBy;

  /// No description provided for @dataOnly.
  ///
  /// In en, this message translates to:
  /// **'Data only. Conclusions are yours to make.'**
  String get dataOnly;

  /// No description provided for @scanToVerify.
  ///
  /// In en, this message translates to:
  /// **'Scan to verify this report\'s authenticity'**
  String get scanToVerify;

  /// No description provided for @osintRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached ({limit} lookups/day). Resets tomorrow.'**
  String osintRateLimit(int limit);

  /// No description provided for @analysisUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Analysis temporarily unavailable. Please try again.'**
  String get analysisUnavailable;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing cached data'**
  String get offlineMode;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @globalRanking.
  ///
  /// In en, this message translates to:
  /// **'Global Ranking'**
  String get globalRanking;

  /// No description provided for @streakFreezeUsed.
  ///
  /// In en, this message translates to:
  /// **'Streak freeze used for this month'**
  String get streakFreezeUsed;

  /// No description provided for @streakFreeze.
  ///
  /// In en, this message translates to:
  /// **'Use Streak Freeze'**
  String get streakFreeze;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
