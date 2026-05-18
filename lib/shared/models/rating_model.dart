class RatingModel {
  final String id;
  final String raterId;
  final String ratedId;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.raterId,
    required this.ratedId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        id: json['id'] as String,
        raterId: json['rater_id'] as String,
        ratedId: json['rated_id'] as String,
        stars: json['stars'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'rater_id': raterId,
        'rated_id': ratedId,
        'stars': stars,
        'comment': comment,
      };
}
