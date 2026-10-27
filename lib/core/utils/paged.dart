/// One page of a paginated list (`Page[T]` in the API: items, total).
class Paged<T> {
  const Paged({required this.items, required this.total});
  final List<T> items;
  final int total;

  bool get hasMore => items.length < total;
}
