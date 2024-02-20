enum ImageResolutionType {
  original,
  large,
  medium,
  small;

  bool get isOriginal => this == ImageResolutionType.original;

  static ImageResolutionType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'original':
        return ImageResolutionType.original;
      case 'large':
        return ImageResolutionType.large;
      case 'medium':
        return ImageResolutionType.medium;
      case 'small':
        return ImageResolutionType.small;
      default:
        return ImageResolutionType.original;
    }
  }

  String get name {
    switch (this) {
      case ImageResolutionType.original:
        return 'Original';
      case ImageResolutionType.large:
        return 'Large';
      case ImageResolutionType.medium:
        return 'Medium';
      case ImageResolutionType.small:
        return 'Small';
      default:
        return 'Original';
    }
  }

  double get height {
    switch (this) {
      case ImageResolutionType.original:
        return 0;
      case ImageResolutionType.large:
        return 720;
      case ImageResolutionType.medium:
        return 420;
      case ImageResolutionType.small:
        return 240;
      default:
        return 0;
    }
  }
}
