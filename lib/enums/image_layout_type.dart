import 'dart:ui';

enum ImageLayoutType {
  oneLine,
  twoLines,
  threeLines,
  fourLines,
  fiveLines;

  static ImageLayoutType fromLines(int? lines) {
    return ImageLayoutType.values.firstWhere((e) => e.lines == (lines ?? 1));
  }

  String get name {
    switch (this) {
      case ImageLayoutType.oneLine:
        return 'One Line';
      case ImageLayoutType.twoLines:
        return 'Two Lines';
      case ImageLayoutType.threeLines:
        return 'Three Lines';
      case ImageLayoutType.fourLines:
        return 'Four Lines';
      case ImageLayoutType.fiveLines:
        return 'Five Lines';
      default:
        return 'One Line';
    }
  }

  int get lines {
    switch (this) {
      case ImageLayoutType.oneLine:
        return 1;
      case ImageLayoutType.twoLines:
        return 2;
      case ImageLayoutType.threeLines:
        return 3;
      case ImageLayoutType.fourLines:
        return 4;
      case ImageLayoutType.fiveLines:
        return 5;
      default:
        return 1;
    }
  }

  // get offset by number of images
  Offset getOffset({
    required int index,
    required int totalImages,
    required double scaledWidth,
  }) {
    int rows = lines;

    int imagesPerRow = (totalImages / rows).ceil();

    int rowIndex = (index / imagesPerRow).floor();
    int columnIndex = index % imagesPerRow;

    double x = columnIndex * scaledWidth;
    double y = rowIndex * scaledWidth;

    if (x > 0) {
      x = x * 1.01;
    }

    if (y > 0) {
      y = y * .57;
    }

    return Offset(x, y);
  }

  // get max width
  double getMaxWidth({
    required int totalImages,
    required double width,
  }) {
    int rows = lines;

    int imagesPerRow = (totalImages / rows).ceil();

    return width / imagesPerRow;
  }

  // get max height
  double getMaxHeight({
    required int totalImages,
    required double height,
  }) {
    int rows = lines;

    return height / rows;
  }
}
