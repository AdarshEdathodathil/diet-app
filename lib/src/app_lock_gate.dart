import 'package:flutter/material.dart';

import 'app_settings.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.settings, required this.child});
  final AppSettings settings;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = true;
  final _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = widget.settings.pinEnabled;
  }

  @override
  void didUpdateWidget(covariant AppLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.settings.pinEnabled) _locked = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && widget.settings.pinEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked || !widget.settings.pinEnabled) return widget.child;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 58,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'Dt Haritha is locked',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'App PIN',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 14),
                FilledButton(onPressed: _unlock, child: const Text('Unlock')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _unlock() {
    if (widget.settings.verifyPin(_pin.text)) {
      setState(() {
        _locked = false;
        _error = null;
        _pin.clear();
      });
    } else {
      setState(() => _error = 'Incorrect PIN.');
    }
  }
}
