class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? fullName;
  final double bonusBalance;
  final int dailyStreak;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fullName,
    required this.bonusBalance,
    required this.dailyStreak,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'],
      fullName: json['full_name'],
      bonusBalance: (json['bonus_balance'] ?? 0).toDouble(),
      dailyStreak: json['daily_streak'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Quest {
  final int id;
  final String title;
  final String? description;
  final int bonusReward;
  final String questType;
  final String actionType;
  final bool isActive;

  Quest({
    required this.id,
    required this.title,
    this.description,
    required this.bonusReward,
    required this.questType,
    required this.actionType,
    required this.isActive,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      bonusReward: json['bonus_reward'],
      questType: json['quest_type'],
      actionType: json['action_type'],
      isActive: json['is_active'],
    );
  }
}

class Prize {
  final int id;
  final String name;
  final String? description;
  final String category;
  final int bonusCost;
  final String? imageUrl;
  final int? stockQuantity;
  final bool isActive;

  Prize({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.bonusCost,
    this.imageUrl,
    this.stockQuantity,
    required this.isActive,
  });

  factory Prize.fromJson(Map<String, dynamic> json) {
    return Prize(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      bonusCost: json['bonus_cost'],
      imageUrl: json['image_url'],
      stockQuantity: json['stock_quantity'],
      isActive: json['is_active'],
    );
  }
}

class Achievement {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final int bonusReward;

  Achievement({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.bonusReward,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      bonusReward: json['bonus_reward'],
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String pseudonym;
  final double bonusEarnedMonth;
  final String league;

  LeaderboardEntry({
    required this.rank,
    required this.pseudonym,
    required this.bonusEarnedMonth,
    required this.league,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      pseudonym: json['pseudonym'],
      bonusEarnedMonth: (json['bonus_earned_month'] ?? 0).toDouble(),
      league: json['league'],
    );
  }
}

class WheelResult {
  final String prizeType;
  final double prizeValue;
  final bool isFree;
  final DateTime spunAt;

  WheelResult({
    required this.prizeType,
    required this.prizeValue,
    required this.isFree,
    required this.spunAt,
  });

  factory WheelResult.fromJson(Map<String, dynamic> json) {
    return WheelResult(
      prizeType: json['prize_type'],
      prizeValue: (json['prize_value'] ?? 0).toDouble(),
      isFree: json['is_free'],
      spunAt: DateTime.parse(json['spun_at']),
    );
  }
}

class DailyCheckinResult {
  final int bonusEarned;
  final int currentStreak;
  final int? streakBonus;
  final String message;

  DailyCheckinResult({
    required this.bonusEarned,
    required this.currentStreak,
    this.streakBonus,
    required this.message,
  });

  factory DailyCheckinResult.fromJson(Map<String, dynamic> json) {
    return DailyCheckinResult(
      bonusEarned: json['bonus_earned'],
      currentStreak: json['current_streak'],
      streakBonus: json['streak_bonus'],
      message: json['message'],
    );
  }
}
