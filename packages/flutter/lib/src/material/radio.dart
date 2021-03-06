// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'theme.dart';
import 'toggleable.dart';

const double _kDiameter = 16.0;
const double _kOuterRadius = _kDiameter / 2.0;
const double _kInnerRadius = 5.0;

/// A material design radio button.
///
/// Used to select between a number of mutually exclusive values. When one
/// radio button in a group is selected, the other radio buttons in the group
/// cease to be selected.
///
/// The radio button itself does not maintain any state. Instead, when the state
/// of the radio button changes, the widget calls the [onChanged] callback.
/// Most widget that use a radio button will listen for the [onChanged]
/// callback and rebuild the radio button with a new [groupValue] to update the
/// visual appearance of the radio button.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [CheckBox]
///  * [Slider]
///  * [Switch]
///  * <https://material.google.com/components/selection-controls.html#selection-controls-radio-button>
class Radio<T> extends StatefulWidget {
  /// Creates a material design radio button.
  ///
  /// The radio button itself does not maintain any state. Instead, when the state
  /// of the radio button changes, the widget calls the [onChanged] callback.
  /// Most widget that use a radio button will listen for the [onChanged]
  /// callback and rebuild the radio button with a new [groupValue] to update the
  /// visual appearance of the radio button.
  ///
  /// * [value] and [groupValue] together determines whether the radio button is selected.
  /// * [onChanged] is when the user selects this radio button.
  const Radio({
    Key key,
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.activeColor
  }) : super(key: key);

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for this group of radio buttons.
  ///
  /// This radio button is considered selected if its [value] matches the
  /// [groupValue].
  final T groupValue;

  /// Called when the user selects this radio button.
  ///
  /// The radio button passes [value] as a parameter to this callback. The radio
  /// button does not actually change state until the parent widget rebuilds the
  /// radio button with the new [groupValue].
  ///
  /// If null, the radio button will be displayed as disabled.
  ///
  /// The callback provided to onChanged should update the state of the parent
  /// [StatefulWidget] using the [State.setState] method, so that the parent
  /// gets rebuilt; for example:
  ///
  /// ```dart
  /// new Radio<SingingCharacter>(
  ///   value: SingingCharacter.lafayette,
  ///   groupValue: _character,
  ///   onChanged: (SingingCharacter newValue) {
  ///     setState(() {
  ///       _character = newValue;
  ///     });
  ///   },
  /// ),
  /// ```
  final ValueChanged<T> onChanged;

  /// The color to use when this radio button is selected.
  ///
  /// Defaults to accent color of the current [Theme].
  final Color activeColor;

  @override
  _RadioState<T> createState() => new _RadioState<T>();
}

class _RadioState<T> extends State<Radio<T>> with TickerProviderStateMixin {
  bool get _enabled => widget.onChanged != null;

  Color _getInactiveColor(ThemeData themeData) {
    return _enabled ? themeData.unselectedWidgetColor : themeData.disabledColor;
  }

  void _handleChanged(bool selected) {
    if (selected)
      widget.onChanged(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData themeData = Theme.of(context);
    return new Semantics(
      checked: widget.value == widget.groupValue,
      child: new _RadioRenderObjectWidget(
        selected: widget.value == widget.groupValue,
        activeColor: widget.activeColor ?? themeData.accentColor,
        inactiveColor: _getInactiveColor(themeData),
        onChanged: _enabled ? _handleChanged : null,
        vsync: this,
      )
    );
  }
}

class _RadioRenderObjectWidget extends LeafRenderObjectWidget {
  const _RadioRenderObjectWidget({
    Key key,
    @required this.selected,
    @required this.activeColor,
    @required this.inactiveColor,
    this.onChanged,
    @required this.vsync,
  }) : assert(selected != null),
       assert(activeColor != null),
       assert(inactiveColor != null),
       assert(vsync != null),
       super(key: key);

  final bool selected;
  final Color inactiveColor;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;

  @override
  _RenderRadio createRenderObject(BuildContext context) => new _RenderRadio(
    value: selected,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    vsync: vsync,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderRadio renderObject) {
    renderObject
      ..value = selected
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..onChanged = onChanged
      ..vsync = vsync;
  }
}

class _RenderRadio extends RenderToggleable {
  _RenderRadio({
    bool value,
    Color activeColor,
    Color inactiveColor,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  }): super(
    value: value,
    activeColor: activeColor,
    inactiveColor: inactiveColor,
    onChanged: onChanged,
    size: const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius),
    vsync: vsync,
  );

  @override
  bool get isInteractive => super.isInteractive && !value;

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    paintRadialReaction(canvas, offset, const Offset(kRadialReactionRadius, kRadialReactionRadius));

    final Offset center = (offset & size).center;
    final Color radioColor = onChanged != null ? activeColor : inactiveColor;

    // Outer circle
    final Paint paint = new Paint()
      ..color = Color.lerp(inactiveColor, radioColor, position.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, _kOuterRadius, paint);

    // Inner circle
    if (!position.isDismissed) {
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(center, _kInnerRadius * position.value, paint);
    }
  }
}
