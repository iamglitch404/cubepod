import 'package:cubepod_state/cubepod_state.dart';

class FieldError {
  final String message;
  const FieldError(this.message);

  @override
  String toString() => message;
}

class CubeField<T> {
  final T _initialValue;
  final StateSignal<T> _value;
  final StateSignal<FieldError?> _error = StateSignal(null);
  final StateSignal<bool> _dirty = StateSignal(false);
  final List<FieldError? Function(T)> _validators;

  Signal<T> get valueSignal => _value;
  Signal<FieldError?> get errorSignal => _error;
  Signal<bool> get isDirtySignal => _dirty;

  T get value => _value.value;
  FieldError? get error => _error.value;
  bool get isDirty => _dirty.value;
  bool get isValid => _error.value == null;

  @override
  String toString() =>
      'CubeField(value: $value, error: $error, dirty: $isDirty)';

  CubeField({
    required T initialValue,
    List<FieldError? Function(T)> validators = const [],
  })  : _initialValue = initialValue,
        _value = StateSignal(initialValue),
        _validators = validators;

  void setValue(T val) {
    _value.value = val;
    _dirty.value = true;
    validate();
  }

  bool validate() {
    for (final v in _validators) {
      final err = v(_value.value);
      if (err != null) {
        _error.value = err;
        return false;
      }
    }
    _error.value = null;
    return true;
  }

  void reset() {
    _value.value = _initialValue;
    _error.value = null;
    _dirty.value = false;
  }
}

class Validators {
  static FieldError? Function(String?) required([String msg = 'Required']) {
    return (v) => (v == null || v.isEmpty) ? FieldError(msg) : null;
  }

  static FieldError? Function(String?) minLength(int min, [String? msg]) {
    return (v) => (v != null && v.length < min)
        ? FieldError(msg ?? 'Min $min characters')
        : null;
  }

  static FieldError? Function(String?) maxLength(int max, [String? msg]) {
    return (v) => (v != null && v.length > max)
        ? FieldError(msg ?? 'Max $max characters')
        : null;
  }

  static FieldError? Function(String?) email([String msg = 'Invalid email']) {
    final re = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return (v) => (v != null && !re.hasMatch(v)) ? FieldError(msg) : null;
  }

  static FieldError? Function(String?) pattern(RegExp re,
      [String msg = 'Invalid format']) {
    return (v) => (v != null && !re.hasMatch(v)) ? FieldError(msg) : null;
  }
}

class CubeForm {
  final Map<String, CubeField> _fields;
  final isSubmitting = StateSignal(false);
  late final ComputedSignal<bool> isValidSignal =
      ComputedSignal(() => _fields.values.every((f) => f.isValid));

  CubeForm(this._fields);

  @override
  String toString() =>
      'CubeForm(fields: ${_fields.keys.join(", ")}, valid: ${validate()}, submitting: ${isSubmitting.value})';

  CubeField<T> field<T>(String name) {
    final f = _fields[name];
    if (f == null) throw StateError('Field "$name" not found');
    if (f is! CubeField<T>) {
      throw StateError(
          'CubeForm: Field "$name" is not of type $T (actual: ${f.runtimeType})');
    }
    return f;
  }

  bool validate() {
    var ok = true;
    for (final f in _fields.values) {
      if (!f.validate()) ok = false;
    }
    return ok;
  }

  Map<String, dynamic> get values =>
      _fields.map((k, f) => MapEntry(k, f.value));

  void reset() {
    for (final f in _fields.values) {
      f.reset();
    }
  }

  Future<void> submit(
      Future<void> Function(Map<String, dynamic>) onSubmit) async {
    if (!validate()) return;
    isSubmitting.value = true;
    try {
      await onSubmit(values);
    } finally {
      isSubmitting.value = false;
    }
  }
}
