// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Music Base';

  @override
  String get appearanceSubtitle => 'Tune the workspace to your setup.';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColorLabel => 'Accent color';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentPurple => 'Purple';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentAmber => 'Amber';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageJapanese => '日本語';

  @override
  String get localLibrarySubtitle =>
      'Choose a local directory to scan and use as the library source.';

  @override
  String get currentSource => 'Current source';

  @override
  String get noLocalDirectory => 'No local directory configured.';

  @override
  String get choose => 'Choose';

  @override
  String get scanningCachedMusic =>
      'Scanning in the background. Cached music remains available.';

  @override
  String get smbLibrarySubtitle =>
      'Credentials are stored in platform secure storage.';

  @override
  String get helpSubtitle => 'Learn how to set up and use the application.';

  @override
  String get aboutSubtitle => 'Application version information.';

  @override
  String get userGuide => 'User guide (GitHub Pages)';

  @override
  String get copyLink => 'Copy link';

  @override
  String get couldNotOpenGuide =>
      'Could not open the user guide. The link was copied.';

  @override
  String get userGuideLinkCopied => 'User guide link copied.';

  @override
  String get version => 'Version';
}
