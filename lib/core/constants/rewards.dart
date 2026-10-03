abstract final class Rewards {
  static const xpPerMinute = 2;
  static int focusXp(int minutes) => minutes > 0 ? minutes * xpPerMinute : 0;
}
