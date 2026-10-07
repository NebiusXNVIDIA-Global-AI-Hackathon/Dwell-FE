enum CaseSortOrder {
  newest,
  oldest;

  String get label => switch (this) {
    CaseSortOrder.newest => 'Newest',
    CaseSortOrder.oldest => 'Oldest',
  };
}
