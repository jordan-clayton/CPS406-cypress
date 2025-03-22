// TODO: define this properly
abstract interface class DatabaseService<T> {
  void create(T entry);
  T getEntry();
  List<T> getEntries();
  void update(T entry);
  void delete(T entry);
}
