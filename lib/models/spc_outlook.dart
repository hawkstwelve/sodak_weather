/// Represents the data for a single Storm Prediction Center (SPC) outlook day.
class SpcOutlook {
  final int day;
  final String imgUrl;
  final String discussion;

  SpcOutlook({
    required this.day,
    required this.imgUrl,
    required this.discussion,
  });

  /// Creates an [SpcOutlook] from a JSON object.
  factory SpcOutlook.fromJson(Map<String, dynamic> json) {
    return SpcOutlook(
      day: json['day'],
      imgUrl: json['imgUrl'],
      discussion: json['discussion'],
    );
  }

  /// Converts this [SpcOutlook] object to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'imgUrl': imgUrl,
      'discussion': discussion,
    };
  }
} 