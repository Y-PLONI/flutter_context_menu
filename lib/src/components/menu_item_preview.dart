import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/models/context_menu_item.dart';
import '../widgets/context_menu_state.dart';
import 'menu_item.dart';

/// A stateful widget that builds the preview and manages its lifecycle.
/// This widget is used internally by [MenuItemPreview].
class _MenuItemPreviewStateful<T> extends StatefulWidget {
  final MenuItemPreview<T> item;
  final ContextMenuState menuState;
  final FocusNode? focusNode;

  const _MenuItemPreviewStateful(this.item, this.menuState, this.focusNode,
      {super.key});

  @override
  State<_MenuItemPreviewStateful<T>> createState() =>
      _MenuItemPreviewStatefulState<T>();
}

class _MenuItemPreviewStatefulState<T>
    extends State<_MenuItemPreviewStateful<T>> {
  OverlayEntry? _previewEntry;

  /// Shows the preview panel using an OverlayEntry.
  void _showPreview(PointerEnterEvent event) {
    // If a preview is already showing, do nothing.
    if (_previewEntry != null) return;

    final renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _previewEntry = OverlayEntry(
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final panel = Material(
          elevation: 6,
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            // Apply fixed size if provided, otherwise use max constraints.
            constraints: widget.item.fixedSize != null
                ? BoxConstraints.tight(widget.item.fixedSize!)
                : (widget.item.maxConstraints ??
                    const BoxConstraints(maxWidth: 420, maxHeight: 600)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              // Ensure scrolling if content overflows.
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: widget.item.previewBuilder(ctx),
                ),
              ),
            ),
          ),
        );

        // Position the preview to the side of the menu item.
        // It correctly handles both LTR and RTL directions.
        return PositionedDirectional(
          start: Directionality.of(ctx) == TextDirection.ltr
              ? offset.dx + size.width + 4
              : null,
          end: Directionality.of(ctx) == TextDirection.rtl
              ? MediaQuery.of(ctx).size.width - offset.dx + 4
              : null,
          top: offset.dy,
          child: panel,
        );
      },
    );

    // Insert the preview into the overlay.
    Overlay.of(context, rootOverlay: true).insert(_previewEntry!);
  }

  /// Hides and removes the preview panel.
  void _hidePreview([PointerExitEvent? event]) {
    _previewEntry?.remove();
    _previewEntry = null;
  }

  @override
  void dispose() {
    // Make sure to remove the preview when the widget is disposed.
    _hidePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We create a standard MenuItem to reuse its appearance and behavior.
    final menuItemWidget = MenuItem<T>(
      label: widget.item.label,
      icon: widget.item.icon,
      enabled: widget.item.enabled,
      onSelected: widget.item.onSelected,
      value: widget.item.value,
      color: widget.item.color,
    );

    // The MouseRegion is what triggers the show/hide logic.
    return MouseRegion(
      onEnter: _showPreview,
      onExit: _hidePreview,
      // We call the standard MenuItem's builder to render the item itself.
      child:
          menuItemWidget.builder(context, widget.menuState, widget.focusNode),
    );
  }
}

/// A context menu item that displays a preview panel when hovered.
///
/// This widget provides a flexible way to show additional information or content
/// related to a menu item without requiring a click.
final class MenuItemPreview<T> extends ContextMenuItem<T> {
  /// The text label to display in the menu.
  final String label;

  /// A builder function that creates the widget to be shown in the preview panel.
  final WidgetBuilder previewBuilder;

  /// An optional fixed size for the preview panel.
  /// If provided, the panel will have these exact dimensions.
  /// If `null`, the panel will size itself to its content, up to `maxConstraints`.
  final Size? fixedSize;

  /// The maximum constraints for the preview panel when `fixedSize` is `null`.
  /// Defaults to a max width of 420 and max height of 600.
  final BoxConstraints? maxConstraints;

  /// An optional icon to display next to the label.
  final IconData? icon;

  /// An optional color for the item's icon and text.
  final Color? color;

  const MenuItemPreview({
    required this.label,
    required this.previewBuilder,
    this.fixedSize,
    this.maxConstraints,
    this.icon,
    this.color,
    super.value,
    super.enabled,
    super.onSelected,
  });

  /// This menu item doesn't support submenus.
  @override
  bool get isSubmenuItem => false;

  @override
  Widget builder(BuildContext context, ContextMenuState menuState,
      [FocusNode? focusNode]) {
    // We delegate the building to our internal stateful widget
    // to handle the overlay state.
    return _MenuItemPreviewStateful<T>(this, menuState, focusNode);
  }
}
