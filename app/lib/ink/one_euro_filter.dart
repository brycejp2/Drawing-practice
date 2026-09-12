import 'dart:math' as math;

/// One-Euro low-pass filter: smooths jitter at low speed while keeping lag
/// low at high speed. See Casiez et al., CHI 2012.
class OneEuroFilter {
  OneEuroFilter({this.minCutoff = 1.5, this.beta = 0.05, this.dCutoff = 10});

  /// Cutoff frequency (Hz) at rest. Lower is smoother.
  final double minCutoff;

  /// How much the cutoff rises with speed. Higher reduces lag when moving fast.
  final double beta;

  /// Cutoff for the derivative estimate.
  final double dCutoff;

  double? _x;
  double _dx = 0;
  double? _t;

  void reset() {
    _x = null;
    _dx = 0;
    _t = null;
  }

  double filter(double x, double tSeconds) {
    final px = _x;
    final pt = _t;
    if (px == null || pt == null) {
      _x = x;
      _t = tSeconds;
      return x;
    }
    var dt = tSeconds - pt;
    if (dt <= 0) dt = 1 / 120;
    final dx = (x - px) / dt;
    _dx = _lowpass(dx, _dx, _alpha(dCutoff, dt));
    final cutoff = minCutoff + beta * _dx.abs();
    final fx = _lowpass(x, px, _alpha(cutoff, dt));
    _x = fx;
    _t = tSeconds;
    return fx;
  }

  static double _alpha(double cutoff, double dt) {
    final tau = 1 / (2 * math.pi * cutoff);
    return 1 / (1 + tau / dt);
  }

  static double _lowpass(double x, double prev, double a) => a * x + (1 - a) * prev;
}
