import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api.dart';

// ======================= THEME =======================
const Color kPrimary = Color(0xFF0F766E); // teal
const Color kPrimaryDark = Color(0xFF134E4A);
const Color kAccent = Color(0xFFF59E0B);
const Color kBg = Color(0xFFF3F6F8);
const Color kDanger = Color(0xFFDC2626);
const Color kOk = Color(0xFF16A34A);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary, secondary: kAccent);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5DDE3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccent,
      foregroundColor: Colors.black87,
    ),
  );
}

// ======================= TIỆN ÍCH =======================
void showSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? kDanger : kPrimaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

Future<bool> confirmDialog(BuildContext context, String message, {String okText = 'Xóa'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Xác nhận'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
        TextButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(okText, style: const TextStyle(color: kDanger, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return r == true;
}

DateTime? parseDt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
String fmtTime(dynamic v) {
  final d = parseDt(v);
  return d == null ? '--:--' : DateFormat('HH:mm').format(d);
}

String fmtDate(dynamic v) {
  final d = parseDt(v);
  return d == null ? '' : DateFormat('dd/MM/yyyy').format(d);
}

String fmtMinutes(dynamic m) {
  final n = (m is num) ? m.toInt() : 0;
  return '${n ~/ 60}h${(n % 60).toString().padLeft(2, '0')}';
}

String statusLabel(String s) {
  switch (s) {
    case 'DungGio':
      return 'Đúng giờ';
    case 'DiTre':
      return 'Đi trễ';
    case 'NghiPhep':
      return 'Nghỉ phép';
    case 'ChoDuyet':
      return 'Chờ duyệt';
    case 'DaDuyet':
      return 'Đã duyệt';
    case 'TuChoi':
      return 'Từ chối';
    default:
      return s;
  }
}

Color statusColor(String s) {
  switch (s) {
    case 'DungGio':
    case 'DaDuyet':
      return kOk;
    case 'DiTre':
    case 'ChoDuyet':
      return const Color(0xFFD97706);
    case 'TuChoi':
      return kDanger;
    default:
      return Colors.blueGrey;
  }
}

String roleLabel(String r) {
  switch (r) {
    case 'Admin':
      return 'Quản trị viên';
    case 'NhanVien':
      return 'Nhân viên';
    case 'KhachHang':
      return 'Khách hàng';
    default:
      return r;
  }
}

// ======================= WIDGET CHUNG =======================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAEE)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? bottom;
  const GradientHeader({super.key, required this.title, required this.subtitle, this.trailing, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [kPrimary, Color(0xFF0E9F8E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
        if (bottom != null) ...[const SizedBox(height: 14), bottom!],
      ]),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const StatTile({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, this.icon = Icons.inbox_outlined, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.black26),
      const SizedBox(height: 12),
      Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)),
    ]),
  );
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, size: 56, color: Colors.black38),
        const SizedBox(height: 12),
        Text(error.toString(), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
      ]),
    ),
  );
}

Future<void> logout(BuildContext context) async {
  if (await confirmDialog(context, 'Bạn muốn đăng xuất?', okText: 'Đăng xuất')) {
    await Session.clear();
  }
}

// ======================= FORM ĐỘNG =======================
enum FieldType { text, multiline, number, email, password, date, time, dropdown, boolean }

class FieldSpec {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final List<MapEntry<dynamic, String>> options;
  final IconData? icon;
  const FieldSpec(this.key, this.label,
      {this.type = FieldType.text, this.required = false, this.options = const [], this.icon});
}

Future<Map<String, dynamic>?> showFormDialog(
    BuildContext context, {
      required String title,
      required List<FieldSpec> fields,
      Map<String, dynamic>? initial,
    }) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _FormDialog(title: title, fields: fields, initial: initial ?? {}),
  );
}

class _FormDialog extends StatefulWidget {
  final String title;
  final List<FieldSpec> fields;
  final Map<String, dynamic> initial;
  const _FormDialog({required this.title, required this.fields, required this.initial});
  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, dynamic> _values;
  final Map<String, TextEditingController> _ctrls = {};

  bool _isTextual(FieldType t) => t != FieldType.dropdown && t != FieldType.boolean;

  @override
  void initState() {
    super.initState();
    _values = Map<String, dynamic>.from(widget.initial);
    for (final f in widget.fields) {
      if (_isTextual(f.type)) {
        _ctrls[f.key] = TextEditingController(text: _values[f.key]?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(FieldSpec f) async {
    final cur = DateTime.tryParse(_ctrls[f.key]!.text) ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) _ctrls[f.key]!.text = DateFormat('yyyy-MM-dd').format(d);
  }

  Future<void> _pickTime(FieldSpec f) async {
    TimeOfDay init = TimeOfDay.now();
    final parts = _ctrls[f.key]!.text.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) init = TimeOfDay(hour: h, minute: m);
    }
    final t = await showTimePicker(context: context, initialTime: init);
    if (t != null) {
      _ctrls[f.key]!.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _field(FieldSpec f) {
    final deco = InputDecoration(
      labelText: f.label + (f.required ? ' *' : ''),
      prefixIcon: f.icon == null ? null : Icon(f.icon),
    );
    Widget w;
    switch (f.type) {
      case FieldType.boolean:
        w = SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _values[f.key] == true,
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
        break;
      case FieldType.dropdown:
        final cur = f.options.any((o) => o.key == _values[f.key]) ? _values[f.key] : null;
        w = DropdownButtonFormField<dynamic>(
          value: cur,
          isExpanded: true,
          decoration: deco,
          items: [for (final o in f.options) DropdownMenuItem<dynamic>(value: o.key, child: Text(o.value, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => _values[f.key] = v,
          validator: (v) => f.required && v == null ? 'Vui lòng chọn' : null,
        );
        break;
      case FieldType.date:
      case FieldType.time:
        w = TextFormField(
          controller: _ctrls[f.key],
          readOnly: true,
          decoration: deco.copyWith(suffixIcon: Icon(f.type == FieldType.date ? Icons.calendar_month : Icons.access_time)),
          onTap: () => f.type == FieldType.date ? _pickDate(f) : _pickTime(f),
          validator: (v) => f.required && (v == null || v.isEmpty) ? 'Vui lòng chọn' : null,
        );
        break;
      default:
        w = TextFormField(
          controller: _ctrls[f.key],
          obscureText: f.type == FieldType.password,
          maxLines: f.type == FieldType.multiline ? 3 : 1,
          keyboardType: f.type == FieldType.number
              ? const TextInputType.numberWithOptions(decimal: true, signed: true)
              : f.type == FieldType.email
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: deco,
          validator: (v) {
            final s = (v ?? '').trim();
            if (f.required && s.isEmpty) return 'Không được để trống';
            if (s.isNotEmpty && f.type == FieldType.number && double.tryParse(s.replaceAll(',', '.')) == null) {
              return 'Phải là số';
            }
            if (s.isNotEmpty && f.type == FieldType.email && !s.contains('@')) return 'Email không hợp lệ';
            return null;
          },
        );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: w);
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    final out = <String, dynamic>{};
    for (final f in widget.fields) {
      if (f.type == FieldType.dropdown || f.type == FieldType.boolean) {
        out[f.key] = _values[f.key];
      } else {
        final s = _ctrls[f.key]!.text.trim();
        if (f.type == FieldType.number) {
          final n = double.tryParse(s.replaceAll(',', '.'));
          out[f.key] = n == null ? null : (n == n.roundToDouble() && n.abs() < 1e9 ? n.toInt() : n);
        } else {
          out[f.key] = s;
        }
      }
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 6),
              for (final f in widget.fields) _field(f),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

// ======================= TRANG CRUD TỔNG QUÁT =======================
class CrudPage extends StatefulWidget {
  final String title;
  final bool showAppBar;
  final Future<List<dynamic>> Function() load;
  final String Function(dynamic) titleOf;
  final String Function(dynamic) subtitleOf;
  final Widget Function(dynamic)? leadingOf;
  final Widget Function(dynamic)? badgeOf;
  final Future<List<FieldSpec>> Function(bool isCreate)? loadFields;
  final Map<String, dynamic> createDefaults;
  final Map<String, dynamic> Function(dynamic)? initialOf;
  final Future<void> Function(Map<String, dynamic>)? onCreate;
  final Future<void> Function(dynamic item, Map<String, dynamic>)? onUpdate;
  final Future<void> Function(dynamic item)? onDelete;
  final bool Function(dynamic)? canEdit;
  final bool Function(dynamic)? canDelete;
  final Widget Function(BuildContext, dynamic, VoidCallback)? extraActions;
  final Widget? header;
  final String emptyText;

  const CrudPage({
    super.key,
    required this.title,
    required this.load,
    required this.titleOf,
    required this.subtitleOf,
    this.showAppBar = true,
    this.leadingOf,
    this.badgeOf,
    this.loadFields,
    this.createDefaults = const {},
    this.initialOf,
    this.onCreate,
    this.onUpdate,
    this.onDelete,
    this.canEdit,
    this.canDelete,
    this.extraActions,
    this.header,
    this.emptyText = 'Chưa có dữ liệu. Nhấn "Thêm" để tạo mới.',
  });

  @override
  State<CrudPage> createState() => _CrudPageState();
}

class _CrudPageState extends State<CrudPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void reload() {
    if (!mounted) return;
    setState(() {
      _future = widget.load();
    });
  }

  Future<void> _run(Future<void> Function() job, String okMsg) async {
    try {
      await job();
      if (!mounted) return;
      showSnack(context, okMsg);
      reload();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _add() async {
    List<FieldSpec> fields;
    try {
      fields = await widget.loadFields!(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final r = await showFormDialog(context, title: 'Thêm mới', fields: fields, initial: widget.createDefaults);
    if (r == null) return;
    await _run(() => widget.onCreate!(r), 'Đã thêm thành công');
  }

  Future<void> _edit(dynamic item) async {
    List<FieldSpec> fields;
    try {
      fields = await widget.loadFields!(false);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final r = await showFormDialog(context,
        title: 'Cập nhật', fields: fields, initial: widget.initialOf?.call(item));
    if (r == null) return;
    await _run(() => widget.onUpdate!(item, r), 'Đã cập nhật');
  }

  Future<void> _delete(dynamic item) async {
    if (!await confirmDialog(context, 'Bạn chắc chắn muốn xóa "${widget.titleOf(item)}"?')) return;
    await _run(() => widget.onDelete!(item), 'Đã xóa');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: widget.showAppBar ? AppBar(title: Text(widget.title)) : null,
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Thêm')),
      body: Column(children: [
        if (widget.header != null) widget.header!,
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return ErrorView(error: snap.error!, onRetry: reload);
              final items = snap.data ?? [];
              return RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await _future;
                },
                child: items.isEmpty
                    ? ListView(children: [const SizedBox(height: 60), EmptyState(text: widget.emptyText)])
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (c, i) => _tile(c, items[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _tile(BuildContext c, dynamic item) {
    final canEdit = widget.onUpdate != null && (widget.canEdit?.call(item) ?? true);
    final canDel = widget.onDelete != null && (widget.canDelete?.call(item) ?? true);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(children: [
        widget.leadingOf?.call(item) ??
            CircleAvatar(
              backgroundColor: kPrimary.withOpacity(0.12),
              foregroundColor: kPrimary,
              child: Text(widget.titleOf(item).isEmpty ? '?' : widget.titleOf(item).characters.first.toUpperCase()),
            ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.titleOf(item), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Text(widget.subtitleOf(item), style: const TextStyle(color: Colors.black54, fontSize: 13)),
            if (widget.badgeOf != null) ...[const SizedBox(height: 6), widget.badgeOf!(item)],
          ]),
        ),
        if (widget.extraActions != null) widget.extraActions!(c, item, reload),
        if (canEdit)
          IconButton(
            tooltip: 'Sửa',
            onPressed: () => _edit(item),
            icon: const Icon(Icons.edit_outlined, color: kPrimary),
          ),
        if (canDel)
          IconButton(
            tooltip: 'Xóa',
            onPressed: () => _delete(item),
            icon: const Icon(Icons.delete_outline, color: kDanger),
          ),
      ]),
    );
  }
}
