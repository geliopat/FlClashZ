import 'dart:async';

import 'package:fl_clash/core/event.dart';
import 'package:fl_clash/ui/inherited.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Explicit in-memory recording. Never export endpoints to the general
/// diagnostic report; the core owns both bounded histories.
enum EngineDiagnosticsSection { closed, chains }

class EngineDiagnosticsView extends ConsumerStatefulWidget {
  const EngineDiagnosticsView({
    super.key,
    required this.section,
    this.titleWidget,
  });

  final EngineDiagnosticsSection section;
  final Widget? titleWidget;

  @override
  ConsumerState<EngineDiagnosticsView> createState() => _EngineDiagnosticsViewState();
}

class _EngineDiagnosticsViewState extends ConsumerState<EngineDiagnosticsView> with CoreEventListener {
  bool _busy = false;
  int _generation = 0;
  Timer? _refreshTimer;

  bool _isCurrent(int generation) => mounted &&
      generation == _generation &&
      ref.read(coreStatusProvider) == CoreStatus.connected;

  bool get _showClosed => widget.section == EngineDiagnosticsSection.closed;
  bool get _visible => mounted &&
      PageActivityScope.isActiveOf(context) &&
      ModalRoute.of(context)?.isCurrent != false &&
      TickerMode.valuesOf(context).enabled &&
      ref.read(appVisibleProvider);
  bool _supported = false;
  String? _error;
  int _capacity = 0;
  bool _chain = false;
  List<Map<String, dynamic>> _closed = const [];
  List<Map<String, dynamic>> _chains = const [];

  String _tr(String ru, String en) =>
      Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

  @override
  void initState() {
    super.initState();
    coreEventManager.addListener(this);
    ref.listenManual(coreStatusProvider, (previous, next) {
      if (previous == next || !mounted) return;
      _generation++;
      setState(() {
        _busy = false; _error = null;
        _supported = false; _capacity = 0; _chain = false; _closed = const []; _chains = const [];
      });
      if (next == CoreStatus.connected) {
        Future.microtask(() { if (_visible) _load(); });
      }
    });
    Future.microtask(() { if (_visible && ref.read(coreStatusProvider) == CoreStatus.connected) _load(); });
    // Poll only the open, visible page; no background network probe is
    // initiated by the UI. Chain health itself remains owned by the core.
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_visible && !_busy &&
          ref.read(coreStatusProvider) == CoreStatus.connected) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    _refreshTimer?.cancel();
    coreEventManager.removeListener(this);
    super.dispose();
  }

  @override
  void onClosedFlowChanged() {
    if (_showClosed && _visible && !_busy && _capacity > 0 &&
        ref.read(coreStatusProvider) == CoreStatus.connected) {
      _load();
    }
  }

  Future<void> _load({int? capacity, bool? chain}) async {
    if (!mounted || _busy) return;
    final generation = _generation;
    setState(() { _busy = true; _error = null; });
    try {
      if (ref.read(coreStatusProvider) != CoreStatus.connected) {
        throw StateError(_tr('Ядро не подключено', 'Core not connected'));
      }
      final core = ref.read(coreHandlerProvider);
      final capabilities = await core.getCoreCapabilities();
      if (!_isCurrent(generation)) return;
      final supported = capabilities.containsAll(const {
        'closed-flow-history-v1', 'chain-diagnostics-v1',
      });
      if (!supported) {
        setState(() {
          _supported = false;
          _capacity = 0;
          _chain = false;
          _closed = const [];
          _chains = const [];
        });
        return;
      }
      var snapshot = await core.getEngineDiagnostics();
      if (!_isCurrent(generation)) return;
      if (capacity != null || chain != null) {
        // Each control updates only its setting; preserve the other native
        // setting even after another page has changed it.
        final current = snapshot['settings'] as Map;
        await core.setEngineDiagnostics(
          closedFlowCapacity: capacity ?? current['closedFlowCapacity'] as int,
          chainDiagnostics: chain ?? current['chainDiagnostics'] as bool,
        );
        if (!_isCurrent(generation)) return;
        snapshot = await core.getEngineDiagnostics();
      }
      if (!_isCurrent(generation)) return;
      final settings = snapshot['settings'] as Map;
      List<Map<String, dynamic>> rows(String key) => [
        for (final item in (snapshot[key] as List? ?? const []).whereType<Map>())
          Map<String, dynamic>.from(item),
      ];
      setState(() {
        _supported = true;
        _capacity = settings['closedFlowCapacity'] as int;
        _chain = settings['chainDiagnostics'] as bool;
        _closed = rows('closed');
        _chains = rows('chains');
      });
    } catch (error) {
      if (_isCurrent(generation)) {
        setState(() {
          _error = '$error'; _supported = false;
          _capacity = 0; _chain = false; _closed = const []; _chains = const [];
        });
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  String _join(Object? value) => value is List
      ? value.whereType<String>().join(' → ')
      : '';

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(coreStatusProvider) == CoreStatus.connected;
    final enabled = connected && _supported && !_busy;
    final count = _showClosed ? _closed.length : _chains.length;
    return CommonScaffold(
      title: _showClosed
          ? _tr('Закрытые соединения', 'Closed connections')
          : _tr('Диагностика цепочек', 'Chain diagnostics'),
      titleWidget: widget.titleWidget,
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionsTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        itemCount: count + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return generateSection(
              items: [
                ListItem(
                  title: Text(_tr('Обновить данные', 'Refresh data')),
                  trailing: _busy ? const CommonCircleLoading() : const GlyphIcon(AppGlyphs.sync),
                  onTap: connected && !_busy ? () => _load() : null,
                  subtitle: Text(_error ?? (_supported
                      ? _tr('Записей: $count', 'Records: $count')
                      : _tr('Требуется совместимый адаптер ядра', 'Compatible core adapter required'))),
                ),
                if (_showClosed) ListItem(
                  title: Text(_tr('Закрытые соединения', 'Closed connections')),
                  subtitle: Text(_tr('До 1024 записей в памяти; счётчики на момент закрытия',
                      'Up to 1024 in-memory records; counters at removal')),
                  trailing: Switch(value: _capacity > 0,
                      onChanged: enabled ? (value) => _load(capacity: value ? 1024 : 0) : null),
                ),
                if (!_showClosed) ListItem(
                  title: Text(_tr('Диагностика цепочек', 'Chain diagnostics')),
                  subtitle: Text(_tr('До 256 попыток; не проверка доступности всего каскада',
                      'Up to 256 dial attempts; not an end-to-end health check')),
                  trailing: Switch(value: _chain,
                      onChanged: enabled ? (value) => _load(chain: value) : null),
                ),
              ],
            );
          }
          if (_showClosed) {
            final row = _closed[index - 1];
            return ListItem(
              title: Text(_join(row['chains']).isEmpty ? '${row['id']}' : _join(row['chains'])),
              subtitle: Text('${row['removedAt']} · ${row['rule']} · ↑ ${row['upload']} B · ↓ ${row['download']} B'),
            );
          }
          final row = _chains[index - 1];
          final successful = row['DialSucceeded'] == true;
          final delay = ((row['Duration'] as num?) ?? 0) / 1000000;
          return ListItem(
            title: Text('${row['Group']} · ${row['Target']}'),
            subtitle: Text('${row['Network']} · ${delay.toStringAsFixed(1)} ms · ${_join(row['Chains'])} · '
              '${successful ? _tr('Подключение создано', 'Dial succeeded') : _tr('Ошибка подключения', 'Dial failed')}'),
          );
        },
      ),
    );
  }
}
