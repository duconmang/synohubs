/// Local image mapping for Synology NAS models.
/// Images are stored in assets/images/nas_models/ — fetched from
/// synology.com/img/products/detail/ (public, no auth needed).
class NasModels {
  NasModels._();

  static const String _base = 'assets/images/nas_models';

  /// Map a DSM model string (e.g. "DS923+") to its local asset path.
  static String imageFor(String model) {
    final key = _normalize(model);
    if (_map.containsKey(key)) return '$_base/${_map[key]}.png';
    // Fallback: try matching prefix (e.g. "DS923+" matches "DS923plus")
    for (final entry in _map.entries) {
      if (key.startsWith(
        entry.key.replaceAll('plus', '').replaceAll('xs', ''),
      )) {
        return '$_base/${entry.value}.png';
      }
    }
    return ''; // empty → caller should show fallback icon
  }

  static String _normalize(String model) =>
      model.trim().toLowerCase().replaceAll('+', 'plus');

  static const _map = <String, String>{
    // 1-bay
    'ds118': 'DS118',
    'ds124': 'DS124',
    // 2-bay Value
    'ds218': 'DS218',
    'ds218plus': 'DS218plus',
    'ds220j': 'DS220j',
    'ds220plus': 'DS220plus',
    'ds223': 'DS223',
    'ds223j': 'DS223j',
    'ds225plus': 'DS225plus',
    // 4-bay Value / Play
    'ds416play': 'DS416play',
    'ds418': 'DS418',
    'ds418play': 'DS418play',
    'ds420j': 'DS420j',
    'ds420plus': 'DS420plus',
    'ds423': 'DS423',
    'ds425plus': 'DS425plus',
    // 4-bay Plus (older)
    'ds916plus': 'DS916plus',
    'ds918plus': 'DS918plus',
    'ds920plus': 'DS920plus',
    'ds923plus': 'DS923plus',
    'ds925plus': 'DS925plus',
    // 2-bay Plus
    'ds718plus': 'DS718plus',
    'ds720plus': 'DS720plus',
    'ds723plus': 'DS723plus',
    'ds725plus': 'DS725plus',
    // Slim
    'ds620slim': 'DS620slim',
    // 5-bay
    'ds1019plus': 'DS1019plus',
    'ds1520plus': 'DS1520plus',
    'ds1522plus': 'DS1522plus',
    'ds1525plus': 'DS1525plus',
    // 6-bay
    'ds1618plus': 'DS1618plus',
    'ds1621plus': 'DS1621plus',
    // 8-bay
    'ds1819plus': 'DS1819plus',
    'ds1821plus': 'DS1821plus',
    'ds1825plus': 'DS1825plus',
    // XS+ series
    'ds1823xsplus': 'DS1823xsplus',
    'ds3622xsplus': 'DS3622xsplus',
    // 12-bay
    'ds2422plus': 'DS2422plus',
  };

  /// All known model names (display form).
  static List<String> get allModels => const [
    'DS118',
    'DS124',
    'DS218',
    'DS218+',
    'DS220j',
    'DS220+',
    'DS223',
    'DS223j',
    'DS225+',
    'DS416play',
    'DS418',
    'DS418play',
    'DS420j',
    'DS420+',
    'DS423',
    'DS425+',
    'DS620slim',
    'DS718+',
    'DS720+',
    'DS723+',
    'DS725+',
    'DS916+',
    'DS918+',
    'DS920+',
    'DS923+',
    'DS925+',
    'DS1019+',
    'DS1520+',
    'DS1522+',
    'DS1525+',
    'DS1618+',
    'DS1621+',
    'DS1819+',
    'DS1821+',
    'DS1823xs+',
    'DS1825+',
    'DS2422+',
    'DS3622xs+',
  ];
}
