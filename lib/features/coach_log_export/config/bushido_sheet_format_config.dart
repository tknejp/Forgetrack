class BushidoSheetColor {
  const BushidoSheetColor(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

class BushidoSheetFormatConfig {
  BushidoSheetFormatConfig._();

  // Local app asset. Google Sheets cannot render this local PNG directly.
  //
  // Upload the same file to Firebase Storage, copy its public HTTPS download
  // URL, and paste it into logoImageUrl. Firebase token URLs are fine, e.g.
  // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?alt=media&token=<token>
  static String? logoImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/forgetracker-493415.firebasestorage.app/o/bushido_logo%2Fbushido_logo.png?alt=media&token=a936b3e6-d525-41fc-a823-2457ce70c348';

  static const int logoHeightPx = 128;
  static const int logoWidthPx = 128;

  static const String fontMostserrat = 'Montserrat';
  static const String fontOswald = 'Oswald';
  static const int tableHeaderFontSize = 12;
  static const int tableRowHeightPx = 30;
  static const String coachFillHeaderLabel = 'Vyplní kouč';
  static const String currentWeekLabel = 'Aktuální týden:';
  static const String currentWeekLinkText = 'Přejít';

  static const BushidoSheetColor sheetBackground = BushidoSheetColor(0, 0, 0);
  static const BushidoSheetColor white = BushidoSheetColor(255, 255, 255);
  static const BushidoSheetColor black = BushidoSheetColor(0, 0, 0);

  static const BushidoSheetColor weeklyHeader = BushidoSheetColor(221, 126, 107);
  static const BushidoSheetColor weeklyFooter = BushidoSheetColor(230, 184, 175);
  static const BushidoSheetColor bodyGray = BushidoSheetColor(217, 217, 217);
  static const BushidoSheetColor bodyGrayDark = BushidoSheetColor(183, 183, 183);
  static const BushidoSheetColor noteBody = BushidoSheetColor(255, 242, 204);
  static const BushidoSheetColor targetHeader = BushidoSheetColor(67, 67, 67);
  static const BushidoSheetColor darkBerry = BushidoSheetColor(133, 32, 12);

  // Light tints used by per-metric conditional formatting on the result cell,
  // weekly average row, and daily input cells.
  static const BushidoSheetColor condGood = BushidoSheetColor(234, 244, 226);
  static const BushidoSheetColor condWarn = BushidoSheetColor(255, 246, 214);
  static const BushidoSheetColor condBad = BushidoSheetColor(252, 228, 228);

  static const BushidoSheetColor profileLabel = BushidoSheetColor(255, 217, 102);
  static const BushidoSheetColor profileValue = BushidoSheetColor(255, 229, 153);

  static const List<String> profileLabels = [
    'Jméno',
    'Věk',
    'Váhová kategorie:',
    'Následující závod:',
    currentWeekLabel,
  ];
}
