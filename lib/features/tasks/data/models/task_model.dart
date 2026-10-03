class TaskModel {
  final String id;
  final String title;
  final String category;
  final int xp;
  final bool isCompleted;
  final bool rewardClaimed;

  const TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.xp,
    this.isCompleted = false,
    this.rewardClaimed = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      xp: json['xp'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? category,
    int? xp,
    bool? isCompleted,
    bool? rewardClaimed,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      xp: xp ?? this.xp,
      isCompleted: isCompleted ?? this.isCompleted,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'xp': xp,
      'isCompleted': isCompleted,
      'rewardClaimed': rewardClaimed,
    };
  }
}
