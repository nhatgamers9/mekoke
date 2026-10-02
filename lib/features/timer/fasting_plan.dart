enum FastingPlan {
  h16(16),
  h18(18),
  h20(20),
  omad(23);

  const FastingPlan(this.fastHours);

  final int fastHours;
}
