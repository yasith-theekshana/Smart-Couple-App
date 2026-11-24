import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_theme.dart';
import 'design_system.dart';

enum EditorInput { text, number, positiveNumber, select, date, notes }

typedef EditorField = ({
  String label,
  EditorInput input,
  String value,
  List<String> options,
});

EditorField editField(
  String label, {
  String value = '',
  EditorInput input = EditorInput.text,
  List<String> options = const [],
}) => (label: label, value: value, input: input, options: options);

String editorDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

Future<List<String>?> showEditor(
  BuildContext context,
  String title,
  List<EditorField> fields,
) => showDialog<List<String>>(
  context: context,
  builder: (context) => _EditorDialog(title: title, fields: fields),
);

class _EditorDialog extends StatefulWidget {
  const _EditorDialog({required this.title, required this.fields});
  final String title;
  final List<EditorField> fields;

  @override
  State<_EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends State<_EditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _values = widget.fields
      .map((field) => TextEditingController(text: field.value))
      .toList();

  @override
  void dispose() {
    for (final value in _values) {
      value.dispose();
    }
    super.dispose();
  }

  Widget _field(int index) {
    final field = widget.fields[index];
    final controller = _values[index];
    switch (field.input) {
      case EditorInput.select:
        return DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: field.options.contains(field.value)
              ? field.value
              : null,
          decoration: InputDecoration(labelText: field.label),
          items: [
            for (final option in field.options)
              DropdownMenuItem(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => controller.text = value ?? '',
          validator: (value) => requiredText(context, value),
        );
      case EditorInput.date:
        return TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            labelText: field.label,
            suffixIcon: const Icon(Icons.calendar_month, color: AppColors.gold),
          ),
          validator: (value) => requiredText(context, value),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (date != null && mounted) controller.text = editorDate(date);
          },
        );
      case EditorInput.number:
      case EditorInput.positiveNumber:
        return AppTextField(
          label: field.label,
          controller: controller,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final number = parseAmount(value);
            return number == null ||
                    !number.isFinite ||
                    number < 0 ||
                    (field.input == EditorInput.positiveNumber && number == 0)
                ? context.strings.invalidNumber
                : null;
          },
        );
      case EditorInput.notes:
        return AppTextField(
          label: field.label,
          controller: controller,
          lines: 3,
        );
      case EditorInput.text:
        return AppTextField(
          label: field.label,
          controller: controller,
          validator: (value) => requiredText(context, value),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return AppDialog(
      title: widget.title,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        AppButton(
          s.save,
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, [
                for (final value in _values) value.text.trim(),
              ]);
            }
          },
        ),
      ],
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, _) in widget.fields.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _field(index),
              ),
          ],
        ),
      ),
    );
  }
}
