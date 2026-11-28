import 'dart:async';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class ChainHealthView extends ConsumerStatefulWidget {
  const ChainHealthView({super.key, this.groupName, this.ownerName})
      : assert(groupName == null || ownerName == null);

  final String? groupName;
  final String? ownerName;
  @override
  ConsumerState<ChainHealthView> createState() => _ChainHealthViewState();
}

class _ChainHealthViewState extends ConsumerState<ChainHealthView> {
  bool _busy = false;
  int _generation = 0;
  Timer? _refreshTimer;

  bool _isCurrent(int generation) => mounted &&
      generation == _generation &&
      ref.read(coreStatusProvider) == CoreStatus.connected;

  bool get _visible => mounted && ModalRoute.of(context)?.isCurrent != false &&
      TickerMode.valuesOf(context).enabled && ref.read(appVisibleProvider);
  bool _available = false;
  String? _error;
  List<Map<String, dynamic>> _owners = const [];
  List<Map<String, dynamic>> _jobs = const [];

  String _tr(String ru, String en) =>
      Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

  @override
  void initState() {
    super.initState();
    ref.listenManual(coreStatusProvider, (previous, next) {
      if (previous == next || !mounted) return;
      _generation++;
      setState(() {
        _busy = false; _error = null;
        _available = false; _owners = const []; _jobs = const [];
      });
      if (next == CoreStatus.connected) {
        Future.microtask(() { if (_visible) _refresh(); });
      }
    });
    Future.microtask(() { if (_visible && ref.read(coreStatusProvider) == CoreStatus.connected) _refresh(); });
    // Poll only the open, visible page; no background network probe is
    // initiated by the UI. Chain health itself remains owned by the core.
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_visible && !_busy &&
          ref.read(coreStatusProvider) == CoreStatus.connected) {
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _rows(Object? value) => [
    if (value is List)
      for (final row in value.whereType<Map>()) Map<String, dynamic>.from(row),
  ];

  Future<void> _refresh({Map<String, dynamic>? owner, bool? enabled}) async {
    if (_busy || !mounted) return;
    final generation = _generation;
    setState(() { _busy = true; _error = null; });
    try {
      if (ref.read(coreStatusProvider) != CoreStatus.connected) {
        throw StateError(_tr('Ядро не подключено', 'Core not connected'));
      }
      final core = ref.read(coreHandlerProvider);
      final capabilities = await core.getCoreCapabilities();
      if (!_isCurrent(generation)) return;
      if (!capabilities.contains('chain-health-v1')) {
        setState(() { _available = false; _owners = const []; _jobs = const []; });
        return;
      }
      if (owner != null && enabled != null) {
        await core.setChainHealth(
          name: owner['name'] as String,
          group: owner['group'] as String,
          identity: owner['identity'] as String,
          enabled: enabled,
        );
      }
      if (!_isCurrent(generation)) return;
      final state = await core.getChainHealth();
      if (!_isCurrent(generation)) return;
      setState(() {
        _available = state['available'] == true;
        _owners = _rows(state['owners']);
        _jobs = _rows(state['jobs']);
      });
    } catch (error) {
      if (_isCurrent(generation)) {
        setState(() {
          _error = '$error'; _available = false; _owners = const []; _jobs = const [];
        });
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Map<String, dynamic>? _jobFor(String group) {
    for (final job in _jobs) {
      if ((job['owner'] as Map?)?['group'] == group) return job;
    }
    return null;
  }

  String _results(Map<String, dynamic> job) {
    final error = job['error'];
    if (error is String && error.isNotEmpty) return error;
    final results = _rows(job['results']);
    if (results.isEmpty) return _tr('Ожидается проверка', 'Awaiting probe');
    return results.map((result) {
      final status = result['Verified'] != true
          ? _tr('Не подтверждено', 'Unverified')
          : result['Healthy'] == true
              ? _tr('Доступен', 'Healthy')
              : _tr('Ошибка', 'Failed');
      // Go time.Duration is serialized in nanoseconds. Unverified results
      // are never displayed as successful measurements.
      final delay = result['Delay'];
      final latency = result['Verified'] == true && delay is num && delay > 0
          ? ' · ${(delay / 1000000).toStringAsFixed(1)} ms'
          : '';
      final error = result['Error'];
      final detail = error is String && error.isNotEmpty ? ' · $error' : '';
      return '${result['Member']}: $status$latency$detail';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(coreStatusProvider) == CoreStatus.connected;
    final enabled = connected && _available && !_busy;
    final owners = _owners.where((owner) =>
        (widget.groupName == null || owner['group'] == widget.groupName) &&
        (widget.ownerName == null || owner['name'] == widget.ownerName)).toList();
    final scope = widget.groupName ?? widget.ownerName;
    return CommonScaffold(
      title: scope == null ? 'Chain Health' : 'Chain Health · $scope',
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionsTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        itemCount: owners.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return generateSection(items: [
              ListItem(
                title: Text(_tr('Обновить список и результаты', 'Refresh owners and results')),
                subtitle: Text(_error ?? (_available
                    ? _tr('Проверка по HTTPS 204 через выбранный каскад. Один выходной узел на группу; только новые TCP-соединения.',
                        'HTTPS 204 probes through the selected cascade. One owner per group; new TCP connections only.')
                    : _tr('Требуется ядро с API активной проверки цепочек', 'Core with active chain probe API required'))),
                trailing: _busy ? const CommonCircleLoading() : const GlyphIcon(AppGlyphs.sync),
                onTap: connected && !_busy ? () => _refresh() : null,
              ),
              if (_available && owners.isEmpty)
                ListItem(title: Text(_tr('Нет подходящих каскадов', 'No eligible cascades')),
                    subtitle: Text(_tr('Ядро не сообщило о поддерживаемых цепочках для этого выбора.',
                        'The core reported no supported chains for this selection.'))) ,
            ]);
          }
          final owner = owners[index - 1];
          final job = _jobFor(owner['group'] as String);
          final active = (job?['owner'] as Map?)?['identity'] == owner['identity'];
          return ListItem(
            title: Text('${owner['name']}'),
            subtitle: Text('${owner['group']}${(owner['provider'] as String).isEmpty ? '' : ' · ${owner['provider']}'}'
                '${active && job != null ? '\n${_results(job)}' : job != null ? '\n${_tr('Занято другим выходом', 'Another owner is active')}' : ''}'),
            trailing: Switch(
              value: active,
              onChanged: enabled && (active || job == null)
                  ? (value) => _refresh(owner: owner, enabled: value)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
