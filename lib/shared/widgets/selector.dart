import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import '../../design_system/tokens.dart';
import 'primitives.dart';

Future<T?> selectOption<T>(
  BuildContext context, {
  required String title,
  required Future<List<T>> options,
  required String Function(T) label,
  T? selected,
}) => openSheet<T>(
  context,
  _Selector(title: title, options: options, label: label, selected: selected),
);

class _Selector<T> extends StatefulWidget {
  const _Selector({
    required this.title,
    required this.options,
    required this.label,
    this.selected,
  });
  final String title;
  final Future<List<T>> options;
  final String Function(T) label;
  final T? selected;
  @override
  State<_Selector<T>> createState() => _SelectorState<T>();
}

class _SelectorState<T> extends State<_Selector<T>> {
  String query = '';
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .66,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: context.type.headlineSmall),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<T>>(
              future: widget.options,
              builder: (c, s) {
                if (s.hasError) {
                  return const EmptyState(
                    'Could not load options.',
                    'Close and try again.',
                    icon: CupertinoIcons.exclamationmark_circle,
                  );
                }
                if (!s.hasData) return const Skeleton();
                final options = s.data!;
                final filtered = options
                    .where(
                      (o) => widget
                          .label(o)
                          .toLowerCase()
                          .contains(query.toLowerCase()),
                    )
                    .toList();
                return Column(
                  children: [
                    if (options.length > 6) ...[
                      TextField(
                        onChanged: (v) => setState(() => query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(CupertinoIcons.search, size: 18),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyState(
                              'No matches.',
                              'Try a shorter search.',
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, i) => const Divider(),
                              itemBuilder: (c, i) {
                                final item = filtered[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    widget.label(item),
                                    style: context.type.bodyLarge,
                                  ),
                                  trailing: item == widget.selected
                                      ? Icon(
                                          CupertinoIcons.checkmark,
                                          size: 18,
                                          color: context.colors.sage,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(context, item),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
