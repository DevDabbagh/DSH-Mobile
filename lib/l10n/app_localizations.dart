import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @filmsTab.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get filmsTab;

  /// No description provided for @academyTab.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get academyTab;

  /// No description provided for @discoverTab.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Skip Humanity'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @films.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get films;

  /// No description provided for @studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studio;

  /// No description provided for @academy.
  ///
  /// In en, this message translates to:
  /// **'Academy'**
  String get academy;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @heroFilmTag.
  ///
  /// In en, this message translates to:
  /// **'FILM'**
  String get heroFilmTag;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing Mends Inside'**
  String get heroTitle;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A story of displacement and resilience'**
  String get heroSubtitle;

  /// No description provided for @actionEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get actionEvents;

  /// No description provided for @actionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get actionRead;

  /// No description provided for @actionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get actionAbout;

  /// No description provided for @actionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get actionSupport;

  /// No description provided for @featuredNow.
  ///
  /// In en, this message translates to:
  /// **'Featured Now'**
  String get featuredNow;

  /// No description provided for @featuredCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Political Education for\nFilmmakers'**
  String get featuredCardTitle;

  /// No description provided for @filmCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Mother Tongue'**
  String get filmCardTitle;

  /// No description provided for @readCardTitle.
  ///
  /// In en, this message translates to:
  /// **'We look where the world is told not to look'**
  String get readCardTitle;

  /// No description provided for @readTag.
  ///
  /// In en, this message translates to:
  /// **'LONG FORM'**
  String get readTag;

  /// No description provided for @readArticle.
  ///
  /// In en, this message translates to:
  /// **'The archive as act of resistance'**
  String get readArticle;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Invisible Borders — A Visual Journey'**
  String get eventTitle;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Fri Jul 18, 2026 • Mar Mikhael Center, Beirut'**
  String get eventDate;

  /// No description provided for @academySectionTag.
  ///
  /// In en, this message translates to:
  /// **'ACADEMY'**
  String get academySectionTag;

  /// No description provided for @academyTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn From Reality'**
  String get academyTitle;

  /// No description provided for @academySubtitle.
  ///
  /// In en, this message translates to:
  /// **'In-depth courses from real conflicts & human stories.'**
  String get academySubtitle;

  /// No description provided for @browseCourses.
  ///
  /// In en, this message translates to:
  /// **'Browse Courses'**
  String get browseCourses;

  /// No description provided for @academyCourseName.
  ///
  /// In en, this message translates to:
  /// **'Carolina Rodriguez'**
  String get academyCourseName;

  /// No description provided for @academyCourseRole.
  ///
  /// In en, this message translates to:
  /// **'Political Educator'**
  String get academyCourseRole;

  /// No description provided for @ourImpact.
  ///
  /// In en, this message translates to:
  /// **'Our Impact'**
  String get ourImpact;

  /// No description provided for @impactFilmsLabel.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get impactFilmsLabel;

  /// No description provided for @impactCoursesLabel.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get impactCoursesLabel;

  /// No description provided for @impactRaisedLabel.
  ///
  /// In en, this message translates to:
  /// **'Raised'**
  String get impactRaisedLabel;

  /// No description provided for @ctaTitle.
  ///
  /// In en, this message translates to:
  /// **'Become Part of the Story'**
  String get ctaTitle;

  /// No description provided for @ctaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every action creates change.'**
  String get ctaSubtitle;

  /// No description provided for @ctaFundCourse.
  ///
  /// In en, this message translates to:
  /// **'Fund a Course'**
  String get ctaFundCourse;

  /// No description provided for @ctaDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get ctaDonate;

  /// No description provided for @dshSupporter.
  ///
  /// In en, this message translates to:
  /// **'DSH Supporter'**
  String get dshSupporter;

  /// No description provided for @dshSupporterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock full access & earn loyalty points.'**
  String get dshSupporterSubtitle;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authSignInToContinue;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailAddress;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get authDontHaveAccount;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authJoinUs.
  ///
  /// In en, this message translates to:
  /// **'Join us to get started'**
  String get authJoinUs;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get authFullName;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get authAlreadyHaveAccount;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get authResetPassword;

  /// No description provided for @authEnterEmailToReset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link'**
  String get authEnterEmailToReset;

  /// No description provided for @authSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get authSendLink;

  /// No description provided for @authRememberedPassword.
  ///
  /// In en, this message translates to:
  /// **'Remembered your password? '**
  String get authRememberedPassword;

  /// No description provided for @authVerifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get authVerifyOTP;

  /// No description provided for @authEnterOTPSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to your email'**
  String get authEnterOTPSent;

  /// No description provided for @authOTPCode.
  ///
  /// In en, this message translates to:
  /// **'OTP Code'**
  String get authOTPCode;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authDidntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? '**
  String get authDidntReceiveCode;

  /// No description provided for @authResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get authResend;

  /// No description provided for @onboardingWitness.
  ///
  /// In en, this message translates to:
  /// **'Witness.'**
  String get onboardingWitness;

  /// No description provided for @onboardingUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Understand.'**
  String get onboardingUnderstand;

  /// No description provided for @onboardingAct.
  ///
  /// In en, this message translates to:
  /// **'Act.'**
  String get onboardingAct;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Go beyond the headlines.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore.'**
  String get onboardingExplore;

  /// No description provided for @onboardingLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn.'**
  String get onboardingLearn;

  /// No description provided for @onboardingEngage.
  ///
  /// In en, this message translates to:
  /// **'Engage.'**
  String get onboardingEngage;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Stories that shape our world.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingFund.
  ///
  /// In en, this message translates to:
  /// **'Fund.'**
  String get onboardingFund;

  /// No description provided for @onboardingSupport.
  ///
  /// In en, this message translates to:
  /// **'Support.'**
  String get onboardingSupport;

  /// No description provided for @onboardingChange.
  ///
  /// In en, this message translates to:
  /// **'Change.'**
  String get onboardingChange;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Make a real impact today.'**
  String get onboardingDesc3;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @homeFocusToday.
  ///
  /// In en, this message translates to:
  /// **'FOCUS TODAY'**
  String get homeFocusToday;

  /// No description provided for @homeViewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get homeViewMore;

  /// No description provided for @homeStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get homeStudioTitle;

  /// No description provided for @homeStudioInProduction.
  ///
  /// In en, this message translates to:
  /// **'DSH STUDIO - IN PRODUCTION'**
  String get homeStudioInProduction;

  /// No description provided for @homeStudioPreProduction.
  ///
  /// In en, this message translates to:
  /// **'DSH STUDIO - PRE-PRODUCTION'**
  String get homeStudioPreProduction;

  /// No description provided for @homeInFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'In Focus'**
  String get homeInFocusTitle;

  /// No description provided for @homeYoutubeSeries.
  ///
  /// In en, this message translates to:
  /// **'Youtube Series - 2026'**
  String get homeYoutubeSeries;

  /// No description provided for @homeReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get homeReadMore;

  /// No description provided for @homeMinRead.
  ///
  /// In en, this message translates to:
  /// **'min read'**
  String get homeMinRead;

  /// No description provided for @homeSupportStory.
  ///
  /// In en, this message translates to:
  /// **'Support a Story'**
  String get homeSupportStory;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @filmsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Cinema that'**
  String get filmsHeroTitle;

  /// No description provided for @filmsHeroHighlight.
  ///
  /// In en, this message translates to:
  /// **'refuses silence.'**
  String get filmsHeroHighlight;

  /// No description provided for @filmsExploreDocumentaries.
  ///
  /// In en, this message translates to:
  /// **'Explore documentaries'**
  String get filmsExploreDocumentaries;

  /// No description provided for @filmsExploreFiction.
  ///
  /// In en, this message translates to:
  /// **'Explore fiction'**
  String get filmsExploreFiction;

  /// No description provided for @filmsFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured Films'**
  String get filmsFeatured;

  /// No description provided for @filmsLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get filmsLibrary;

  /// No description provided for @filmsWatchTrailer.
  ///
  /// In en, this message translates to:
  /// **'Watch trailer'**
  String get filmsWatchTrailer;

  /// No description provided for @filmsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No films yet'**
  String get filmsEmptyTitle;

  /// No description provided for @filmsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New work will appear here as it is published.'**
  String get filmsEmptyBody;

  /// No description provided for @filmsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading films.'**
  String get filmsLoadError;

  /// No description provided for @filmsTitleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 title} other{{count} titles}}'**
  String filmsTitleCount(int count);

  /// No description provided for @filmsFilmCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 film} other{{count} films}}'**
  String filmsFilmCount(int count);

  /// No description provided for @filmFormDocumentary.
  ///
  /// In en, this message translates to:
  /// **'Documentary'**
  String get filmFormDocumentary;

  /// No description provided for @filmFormFiction.
  ///
  /// In en, this message translates to:
  /// **'Fiction'**
  String get filmFormFiction;

  /// No description provided for @filmFormatShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get filmFormatShort;

  /// No description provided for @filmFormatSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get filmFormatSeries;

  /// No description provided for @filmStageDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get filmStageDevelopment;

  /// No description provided for @filmStageProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get filmStageProduction;

  /// No description provided for @filmStagePostProduction.
  ///
  /// In en, this message translates to:
  /// **'Post-production'**
  String get filmStagePostProduction;

  /// No description provided for @filmStageFestivals.
  ///
  /// In en, this message translates to:
  /// **'Festivals'**
  String get filmStageFestivals;

  /// No description provided for @filmStageDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get filmStageDistribution;

  /// No description provided for @filmStageImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get filmStageImpact;

  /// No description provided for @filmWatchTrailerFull.
  ///
  /// In en, this message translates to:
  /// **'Watch Trailer'**
  String get filmWatchTrailerFull;

  /// No description provided for @filmSectionSynopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get filmSectionSynopsis;

  /// No description provided for @filmSectionEditorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial Context'**
  String get filmSectionEditorial;

  /// No description provided for @filmSectionCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get filmSectionCredits;

  /// No description provided for @filmSectionStills.
  ///
  /// In en, this message translates to:
  /// **'Film Stills'**
  String get filmSectionStills;

  /// No description provided for @filmSectionFestivals.
  ///
  /// In en, this message translates to:
  /// **'Festivals & Awards'**
  String get filmSectionFestivals;

  /// No description provided for @filmSectionScreenings.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Screenings'**
  String get filmSectionScreenings;

  /// No description provided for @filmSectionPress.
  ///
  /// In en, this message translates to:
  /// **'Press'**
  String get filmSectionPress;

  /// No description provided for @filmSectionMore.
  ///
  /// In en, this message translates to:
  /// **'More from DSH'**
  String get filmSectionMore;

  /// No description provided for @filmReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get filmReadMore;

  /// No description provided for @filmReadLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get filmReadLess;

  /// No description provided for @filmCreditDirector.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get filmCreditDirector;

  /// No description provided for @filmCreditProducer.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get filmCreditProducer;

  /// No description provided for @filmCreditCoProduction.
  ///
  /// In en, this message translates to:
  /// **'Co-production'**
  String get filmCreditCoProduction;

  /// No description provided for @filmCreditLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get filmCreditLanguage;

  /// No description provided for @filmCreditCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get filmCreditCountry;

  /// No description provided for @filmRsvp.
  ///
  /// In en, this message translates to:
  /// **'RSVP'**
  String get filmRsvp;

  /// No description provided for @filmSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Us Make More Films'**
  String get filmSupportTitle;

  /// No description provided for @filmSupportBody.
  ///
  /// In en, this message translates to:
  /// **'Your support funds stories the world looks away from.'**
  String get filmSupportBody;

  /// No description provided for @filmSupportCta.
  ///
  /// In en, this message translates to:
  /// **'Support DSH'**
  String get filmSupportCta;

  /// No description provided for @filmNotFound.
  ///
  /// In en, this message translates to:
  /// **'This film isn’t available.'**
  String get filmNotFound;

  /// No description provided for @filmDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String filmDurationMinutes(String count);

  /// No description provided for @studioTab.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get studioTab;

  /// No description provided for @studioHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Work that'**
  String get studioHeroTitle;

  /// No description provided for @studioHeroHighlight.
  ///
  /// In en, this message translates to:
  /// **'refuses silence.'**
  String get studioHeroHighlight;

  /// No description provided for @studioHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Docuseries, podcasts, videocasts, and series at the intersection of documentary, journalism, and art.'**
  String get studioHeroBody;

  /// No description provided for @studioExploreWork.
  ///
  /// In en, this message translates to:
  /// **'Explore work'**
  String get studioExploreWork;

  /// No description provided for @studioGetInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get studioGetInTouch;

  /// No description provided for @studioWhatWeDo.
  ///
  /// In en, this message translates to:
  /// **'What Studio does'**
  String get studioWhatWeDo;

  /// No description provided for @studioFeaturedProject.
  ///
  /// In en, this message translates to:
  /// **'Featured project'**
  String get studioFeaturedProject;

  /// No description provided for @studioLibrary.
  ///
  /// In en, this message translates to:
  /// **'Studio Library'**
  String get studioLibrary;

  /// No description provided for @studioViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get studioViewAll;

  /// No description provided for @studioViewEpisodes.
  ///
  /// In en, this message translates to:
  /// **'View episodes'**
  String get studioViewEpisodes;

  /// No description provided for @studioClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get studioClose;

  /// No description provided for @studioFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get studioFilterAll;

  /// No description provided for @studioFormatDocuseries.
  ///
  /// In en, this message translates to:
  /// **'Docuseries'**
  String get studioFormatDocuseries;

  /// No description provided for @studioFormatVideocasts.
  ///
  /// In en, this message translates to:
  /// **'Videocasts'**
  String get studioFormatVideocasts;

  /// No description provided for @studioFormatPodcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get studioFormatPodcasts;

  /// No description provided for @studioFormatSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get studioFormatSeries;

  /// No description provided for @studioFormatOther.
  ///
  /// In en, this message translates to:
  /// **'Other media'**
  String get studioFormatOther;

  /// No description provided for @studioCapDocuseriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Docuseries'**
  String get studioCapDocuseriesTitle;

  /// No description provided for @studioCapDocuseriesBody.
  ///
  /// In en, this message translates to:
  /// **'Long-form documentary series on political, social, and cultural subjects.'**
  String get studioCapDocuseriesBody;

  /// No description provided for @studioCapPodcastsTitle.
  ///
  /// In en, this message translates to:
  /// **'Podcasts & Videocasts'**
  String get studioCapPodcastsTitle;

  /// No description provided for @studioCapPodcastsBody.
  ///
  /// In en, this message translates to:
  /// **'Conversations that challenge the dominant frame and stay with a subject over time.'**
  String get studioCapPodcastsBody;

  /// No description provided for @studioCapProductionTitle.
  ///
  /// In en, this message translates to:
  /// **'Production Capacity'**
  String get studioCapProductionTitle;

  /// No description provided for @studioCapProductionBody.
  ///
  /// In en, this message translates to:
  /// **'Developing and making work with partners, broadcasters, and movements.'**
  String get studioCapProductionBody;

  /// No description provided for @studioCapSeriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get studioCapSeriesTitle;

  /// No description provided for @studioCapSeriesBody.
  ///
  /// In en, this message translates to:
  /// **'Episodic audio and video, and the original media built around it.'**
  String get studioCapSeriesBody;

  /// No description provided for @studioEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No studio work yet'**
  String get studioEmptyTitle;

  /// No description provided for @studioEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Projects will appear here as they are published.'**
  String get studioEmptyBody;

  /// No description provided for @studioLoadError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading studio work.'**
  String get studioLoadError;

  /// No description provided for @studioFooter.
  ///
  /// In en, this message translates to:
  /// **'© {year} DSH Studio. All rights reserved.'**
  String studioFooter(String year);

  /// No description provided for @studioEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 episode} other{{count} episodes}}'**
  String studioEpisodeCount(int count);

  /// No description provided for @studioExploreEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Explore episodes'**
  String get studioExploreEpisodes;

  /// No description provided for @studioRequestScreener.
  ///
  /// In en, this message translates to:
  /// **'Request a screener'**
  String get studioRequestScreener;

  /// No description provided for @studioRequestScreening.
  ///
  /// In en, this message translates to:
  /// **'Request a screening'**
  String get studioRequestScreening;

  /// No description provided for @studioContactDistribution.
  ///
  /// In en, this message translates to:
  /// **'Contact for distribution'**
  String get studioContactDistribution;

  /// No description provided for @studioCreditProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get studioCreditProduction;

  /// No description provided for @studioCreditCoProduction.
  ///
  /// In en, this message translates to:
  /// **'Co-production'**
  String get studioCreditCoProduction;

  /// No description provided for @studioCreditHosts.
  ///
  /// In en, this message translates to:
  /// **'Hosts & creators'**
  String get studioCreditHosts;

  /// No description provided for @studioCreditPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get studioCreditPartners;

  /// No description provided for @studioCreditYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get studioCreditYear;

  /// No description provided for @studioCreditLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get studioCreditLanguage;

  /// No description provided for @studioCreditDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get studioCreditDirection;

  /// No description provided for @studioCreditFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get studioCreditFormat;

  /// No description provided for @studioCreditCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get studioCreditCountry;

  /// No description provided for @studioCreditDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get studioCreditDuration;

  /// No description provided for @studioSectionEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get studioSectionEpisodes;

  /// No description provided for @studioSeasonNumber.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String studioSeasonNumber(String number);

  /// No description provided for @studioEpisodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String studioEpisodeNumber(String number);

  /// No description provided for @studioViewEpisode.
  ///
  /// In en, this message translates to:
  /// **'View episode'**
  String get studioViewEpisode;

  /// No description provided for @studioKnowMore.
  ///
  /// In en, this message translates to:
  /// **'Know more'**
  String get studioKnowMore;

  /// No description provided for @studioGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest: {name}'**
  String studioGuest(String name);

  /// No description provided for @studioShareProject.
  ///
  /// In en, this message translates to:
  /// **'Share this project'**
  String get studioShareProject;

  /// No description provided for @studioShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get studioShare;

  /// No description provided for @studioProjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'This project isn’t available.'**
  String get studioProjectNotFound;

  /// No description provided for @studioNoEpisodes.
  ///
  /// In en, this message translates to:
  /// **'No episodes published yet.'**
  String get studioNoEpisodes;

  /// No description provided for @studioSectionGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get studioSectionGallery;

  /// No description provided for @studioMoreEpisodes.
  ///
  /// In en, this message translates to:
  /// **'More episodes'**
  String get studioMoreEpisodes;

  /// No description provided for @studioEpisodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'This episode isn’t available.'**
  String get studioEpisodeNotFound;

  /// No description provided for @authRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authRequiredTitle;

  /// No description provided for @authRequiredEnroll.
  ///
  /// In en, this message translates to:
  /// **'You need an account to enrol in a course, so your progress is saved to you.'**
  String get authRequiredEnroll;

  /// No description provided for @authRequiredDonate.
  ///
  /// In en, this message translates to:
  /// **'You need an account so your donation is recorded against your profile.'**
  String get authRequiredDonate;

  /// No description provided for @authRequiredSave.
  ///
  /// In en, this message translates to:
  /// **'You need an account so your saved items stay with you.'**
  String get authRequiredSave;

  /// No description provided for @authRequiredGeneric.
  ///
  /// In en, this message translates to:
  /// **'You need an account to do this.'**
  String get authRequiredGeneric;

  /// No description provided for @authCancel.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get authCancel;

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re browsing as a guest'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow your donations, saved work, and course progress.'**
  String get profileGuestBody;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account?'**
  String get profileSignOutConfirm;

  /// No description provided for @profileMember.
  ///
  /// In en, this message translates to:
  /// **'DSH Member'**
  String get profileMember;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profilePrivacy;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get profileTerms;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get profileHelp;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About DSH'**
  String get profileAbout;

  /// No description provided for @profileBilling.
  ///
  /// In en, this message translates to:
  /// **'Subscription & billing'**
  String get profileBilling;

  /// No description provided for @profileDonationSettings.
  ///
  /// In en, this message translates to:
  /// **'Donation settings'**
  String get profileDonationSettings;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New films, episodes and course announcements will appear here.'**
  String get notificationsEmptyBody;

  /// No description provided for @notificationsGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your notifications'**
  String get notificationsGuestTitle;

  /// No description provided for @notificationsGuestBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications are tied to your account, so there is nothing to show while you are browsing as a guest.'**
  String get notificationsGuestBody;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @studioStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get studioStatusOngoing;

  /// No description provided for @studioStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get studioStatusComplete;

  /// No description provided for @studioStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get studioStatusUpcoming;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filterClearAll;

  /// No description provided for @filterShowResults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No results} one{Show 1 result} other{Show {count} results}}'**
  String filterShowResults(int count);

  /// No description provided for @filterStage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get filterStage;

  /// No description provided for @filterForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get filterForm;

  /// No description provided for @filterFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get filterFormat;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterAny.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAny;

  /// No description provided for @filterNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get filterNoResults;

  /// No description provided for @filterClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get filterClearFilters;

  /// No description provided for @searchFilmsHint.
  ///
  /// In en, this message translates to:
  /// **'Search films'**
  String get searchFilmsHint;

  /// No description provided for @searchStudioHint.
  ///
  /// In en, this message translates to:
  /// **'Search studio work'**
  String get searchStudioHint;

  /// No description provided for @filmsAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All films'**
  String get filmsAllTitle;

  /// No description provided for @studioAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All studio work'**
  String get studioAllTitle;

  /// No description provided for @impactStoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get impactStoriesLabel;

  /// No description provided for @supportWhereItGoes.
  ///
  /// In en, this message translates to:
  /// **'Where your support goes'**
  String get supportWhereItGoes;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchEverythingHint.
  ///
  /// In en, this message translates to:
  /// **'Search films, studio, courses…'**
  String get searchEverythingHint;

  /// No description provided for @searchIdle.
  ///
  /// In en, this message translates to:
  /// **'Type at least 3 letters, or press search on the keyboard.'**
  String get searchIdle;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{query}”.'**
  String searchNoResults(String query);

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecent;

  /// No description provided for @searchBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get searchBrowse;

  /// No description provided for @searchClearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearRecent;

  /// No description provided for @searchResultFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get searchResultFilm;

  /// No description provided for @searchResultStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get searchResultStudio;

  /// No description provided for @searchResultCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get searchResultCourse;

  /// No description provided for @aboutWhatWeDo.
  ///
  /// In en, this message translates to:
  /// **'What we do'**
  String get aboutWhatWeDo;

  /// No description provided for @browseRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get browseRead;

  /// No description provided for @browseEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get browseEvents;

  /// No description provided for @browseImpact.
  ///
  /// In en, this message translates to:
  /// **'Impact'**
  String get browseImpact;

  /// No description provided for @browseSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get browseSupport;

  /// No description provided for @homeSlowConnection.
  ///
  /// In en, this message translates to:
  /// **'This is taking a while. Check your connection, then pull down to refresh.'**
  String get homeSlowConnection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
