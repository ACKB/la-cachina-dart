import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_lib;
import '../../domain/usecases/product_usecases.dart';
import 'dashboard_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estado del formulario de nuevo producto — inmutable
// ─────────────────────────────────────────────────────────────────────────────

class KitItemForm {
  final String componentName;
  final int    quantity;
  const KitItemForm({required this.componentName, required this.quantity});
  Map<String, dynamic> toMap() => {'component_name': componentName, 'quantity': quantity};
}

class NewProductFormState {
  final String title;
  final String description;
  final String priceRaw;
  final String categoryId;
  final String categoryName;
  final List<XFile> images;
  final Map<String, String> errors;
  final bool isSubmitting;
  final bool isSuccess;

  // PB-03: Campos técnicos
  final String model;
  final String conditionRaw;     // texto del slider '1'-'10'
  final String datasheetUrl;
  final String tips;
  final String githubUrl;

  // PB-09/10/11: Kits
  final String type;             // 'PRODUCT' | 'KIT'
  final String courseLabel;
  final List<KitItemForm> kitItems;

  const NewProductFormState({
    this.title         = '',
    this.description   = '',
    this.priceRaw      = '',
    this.categoryId    = '',
    this.categoryName  = '',
    this.images        = const [],
    this.errors        = const {},
    this.isSubmitting  = false,
    this.isSuccess     = false,
    this.model         = '',
    this.conditionRaw  = '7',
    this.datasheetUrl  = '',
    this.tips          = '',
    this.githubUrl     = '',
    this.type          = 'PRODUCT',
    this.courseLabel   = '',
    this.kitItems      = const [],
  });

  bool get isKit => type == 'KIT';
  int  get conditionValue => int.tryParse(conditionRaw) ?? 7;
  int  get descriptionLength => description.length;

  NewProductFormState copyWith({
    String? title, String? description, String? priceRaw,
    String? categoryId, String? categoryName,
    List<XFile>? images, Map<String, String>? errors,
    bool? isSubmitting, bool? isSuccess,
    String? model, String? conditionRaw, String? datasheetUrl,
    String? tips, String? githubUrl,
    String? type, String? courseLabel,
    List<KitItemForm>? kitItems,
  }) => NewProductFormState(
    title:        title        ?? this.title,
    description:  description  ?? this.description,
    priceRaw:     priceRaw     ?? this.priceRaw,
    categoryId:   categoryId   ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    images:       images       ?? this.images,
    errors:       errors       ?? this.errors,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    isSuccess:    isSuccess    ?? this.isSuccess,
    model:        model        ?? this.model,
    conditionRaw: conditionRaw ?? this.conditionRaw,
    datasheetUrl: datasheetUrl ?? this.datasheetUrl,
    tips:         tips         ?? this.tips,
    githubUrl:    githubUrl    ?? this.githubUrl,
    type:         type         ?? this.type,
    courseLabel:  courseLabel  ?? this.courseLabel,
    kitItems:     kitItems     ?? this.kitItems,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier del formulario
// ─────────────────────────────────────────────────────────────────────────────

class NewProductNotifier extends StateNotifier<NewProductFormState> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  NewProductNotifier(this._ref) : super(const NewProductFormState());

  // ── Campos básicos ────────────────────────────────────────────────────────

  void setTitle(String v)       => state = state.copyWith(title: v, errors: _clearError('title'));
  void setDescription(String v) => state = state.copyWith(description: v, errors: _clearError('description'));
  void setPrice(String v)       => state = state.copyWith(priceRaw: v, errors: _clearError('price'));
  void setCategory(String id, String name) =>
      state = state.copyWith(categoryId: id, categoryName: name, errors: _clearError('category'));

  // ── Campos técnicos PB-03 ─────────────────────────────────────────────────

  void setModel(String v)       => state = state.copyWith(model: v);
  void setCondition(String v)   => state = state.copyWith(conditionRaw: v);
  void setDatasheetUrl(String v)=> state = state.copyWith(datasheetUrl: v, errors: _clearError('datasheetUrl'));
  void setTips(String v)        => state = state.copyWith(tips: v);
  void setGithubUrl(String v)   => state = state.copyWith(githubUrl: v, errors: _clearError('githubUrl'));

  // ── Kits PB-09/10/11 ──────────────────────────────────────────────────────

  void setType(String t)        => state = state.copyWith(type: t);
  void setCourseLabel(String v) => state = state.copyWith(courseLabel: v);

  void addKitItem() {
    state = state.copyWith(
      kitItems: [...state.kitItems, const KitItemForm(componentName: '', quantity: 1)],
    );
  }

  void updateKitItem(int index, {String? name, int? qty}) {
    final items = List<KitItemForm>.from(state.kitItems);
    items[index] = KitItemForm(
      componentName: name ?? items[index].componentName,
      quantity:      qty  ?? items[index].quantity,
    );
    state = state.copyWith(kitItems: items);
  }

  void removeKitItem(int index) {
    final items = List<KitItemForm>.from(state.kitItems)..removeAt(index);
    state = state.copyWith(kitItems: items);
  }

  // ── Imágenes PB-02 ────────────────────────────────────────────────────────

  Future<void> pickImages() async {
    if (state.images.length >= 3) return;
    final picked = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 800);
    if (picked.isEmpty) return;

    final remaining = 3 - state.images.length;
    final newFiles = <XFile>[];
    final errs = Map<String, String>.from(state.errors);

    for (final x in picked.take(remaining)) {
      // PB-02: Validar formato usando x.name para soporte multiplataforma
      final ext = path_lib.extension(x.name).toLowerCase();
      if (!['.jpg', '.jpeg', '.png'].contains(ext)) {
        errs['images'] = 'Solo se permiten imágenes JPG o PNG.';
        continue;
      }
      // PB-02: Validar tamaño usando x.length() compatible con web
      final size = await x.length();
      if (size > 5 * 1024 * 1024) {
        errs['images'] = 'Cada imagen debe pesar menos de 5 MB.';
        continue;
      }
      newFiles.add(x);
    }

    state = state.copyWith(
      images: [...state.images, ...newFiles],
      errors: errs..remove('images_ok'),
    );
  }

  void removeImage(int index) {
    final updated = List<XFile>.from(state.images)..removeAt(index);
    state = state.copyWith(images: updated);
  }

  // ── Validación ────────────────────────────────────────────────────────────

  Map<String, String> _validate() {
    final e = <String, String>{};

    final t = state.title.trim();
    if (t.length < 3)       e['title'] = 'El título debe tener al menos 3 caracteres.';
    else if (t.length > 80) e['title'] = 'El título no puede superar 80 caracteres.';

    final d = state.description.trim();
    if (d.length < 10)       e['description'] = 'Describe el producto con al menos 10 caracteres.';
    else if (d.length > 500) e['description'] = 'La descripción no puede superar 500 caracteres.';

    final price = double.tryParse(state.priceRaw.trim());
    if (price == null || price <= 0) e['price'] = 'Ingresa un precio mayor a S/ 0.';
    else if (price > 9999)           e['price'] = 'El precio no puede superar S/ 9,999.';

    if (state.categoryId.isEmpty) e['category'] = 'Selecciona una categoría.';
    if (state.images.isEmpty)     e['images']   = 'Agrega al menos una foto del producto.';

    // PB-03: Validar URL datasheet
    final ds = state.datasheetUrl.trim();
    if (ds.isNotEmpty && !Uri.tryParse(ds)!.hasAbsolutePath) {
      e['datasheetUrl'] = 'Ingresa un enlace válido (https://...)';
    }

    // PB-12: Validar URL GitHub
    final gh = state.githubUrl.trim();
    if (gh.isNotEmpty && !(gh.startsWith('http://') || gh.startsWith('https://'))) {
      e['githubUrl'] = 'Ingresa un enlace válido (https://...)';
    }

    // PB-09: Kit necesita al menos un componente y curso
    if (state.isKit) {
      if (state.kitItems.isEmpty) e['kitItems'] = 'Agrega al menos un componente al kit.';
      if (state.courseLabel.trim().isEmpty) e['courseLabel'] = 'Indica el curso o ciclo del kit.';
    }

    return e;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit(String userId) async {
    final errors = _validate();
    if (errors.isNotEmpty) { state = state.copyWith(errors: errors); return; }

    state = state.copyWith(isSubmitting: true, errors: {});

    final priceInCentavos = (double.parse(state.priceRaw.trim()) * 100).round();
    final condition       = state.conditionValue;

    final useCase = _ref.read(createProductUseCaseProvider);
    final result  = await useCase(CreateProductParams(
      title:           state.title.trim(),
      description:     state.description.trim(),
      priceInCentavos: priceInCentavos,
      categoryId:      state.categoryId,
      userId:          userId,
      images:          state.images,
      model:           state.model.trim().isEmpty ? null : state.model.trim(),
      condition:       condition,
      datasheetUrl:    state.datasheetUrl.trim().isEmpty ? null : state.datasheetUrl.trim(),
      tips:            state.tips.trim().isEmpty ? null : state.tips.trim(),
      githubUrl:       state.githubUrl.trim().isEmpty ? null : state.githubUrl.trim(),
      type:            state.type,
      courseLabel:     state.courseLabel.trim().isEmpty ? null : state.courseLabel.trim(),
      kitItems:        state.kitItems.map((i) => i.toMap()).toList(),
    ));

    result.fold(
      (failure) => state = state.copyWith(isSubmitting: false, errors: {'global': failure.message}),
      (_) {
        state = state.copyWith(isSubmitting: false, isSuccess: true);
        _ref.read(dashboardProvider.notifier).refresh();
      },
    );
  }

  void reset() => state = const NewProductFormState();

  Map<String, String> _clearError(String key) =>
      Map<String, String>.from(state.errors)..remove(key);
}

final newProductProvider =
    StateNotifierProvider.autoDispose<NewProductNotifier, NewProductFormState>(
  (ref) => NewProductNotifier(ref),
);
