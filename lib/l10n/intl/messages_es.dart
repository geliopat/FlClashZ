// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'es';

  static String m0(count) =>
      "${Intl.plural(count, one: '${count} seleccionada', other: '${count} seleccionadas')}";

  static String m1(name) => "${name} añadido a proxies locales";

  static String m2(name) => "${name} ya está en proxies locales";

  static String m3(count, skipped) =>
      "${count} por añadir, ${skipped} omitidos por ya existir";

  static String m4(detail) => "No se pudieron borrar los datos: ${detail}";

  static String m5(code) =>
      "Windows se negó a ejecutar FlClashCore.exe (error ${code}). Una directiva de control de aplicaciones, como Smart App Control o AppLocker, bloquea los programas sin firmar; permite FlClashX en esa directiva o desactívala e inténtalo de nuevo.";

  static String m6(name) =>
      "La app no pudo terminar de iniciarse dos veces seguidas. Para romper el ciclo, se ha deseleccionado el perfil ${name} y se ha omitido la configuración automática. Puedes volver a seleccionarlo en cualquier momento.";

  static String m7(count, label) =>
      "${Intl.plural(count, one: 'Se descartó 1 regla SUB-RULE, porque los perfiles personalizados no admiten subreglas', other: 'Se descartaron ${label} reglas SUB-RULE, porque los perfiles personalizados no admiten subreglas')}";

  static String m8(message) =>
      "El núcleo no puede interpretar este proxy: ${message}";

  static String m9(proxy, target) =>
      "${proxy} marca a través de ${target}, que lleva de vuelta a ${proxy}, por lo que la marcación entra en bucle";

  static String m10(name) =>
      "El nombre ${name} ya lo usa otro proxy o grupo de proxies";

  static String m11(path) =>
      "Los grupos de proxies se referencian entre sí en bucle: ${path}";

  static String m12(name) =>
      "El respaldo si está vacío debe ser un proxy, pero ${name} no existe o es un grupo de proxies";

  static String m13(name, message) =>
      "${name} no es una expresión regular válida: ${message}";

  static String m14(name) => "El proxy de marcación ${name} no existe";

  static String m15(names) =>
      "Estos proveedores de proxies no existen: ${names}";

  static String m16(names) => "Estos proxies o políticas no existen: ${names}";

  static String m17(name) =>
      "${name} es un nombre de política integrada y no se puede usar aquí";

  static String m18(count) =>
      "${count} elementos tienen problemas, y aplicar este perfil puede fallar";

  static String m19(count) =>
      "${Intl.plural(count, one: 'hace 1 día', other: 'hace ${count} días')}";

  static String m20(count) => "${Intl.plural(count, other: 'hace ${count} d')}";

  static String m21(label) =>
      "¿Seguro que quieres eliminar los elementos seleccionados (${label})?";

  static String m22(label) =>
      "¿Seguro que quieres eliminar este elemento (${label})?";

  static String m23(label) => "Detalles de ${label}";

  static String m24(name) =>
      "La marcación a través de ${name} lleva de vuelta al proxy que lo usa, por lo que se detuvo la conexión";

  static String m25(label) => "${label} no puede estar vacío";

  static String m26(label) => "${label} ya existe";

  static String m27(address) =>
      "El controlador externo permite controlar el núcleo en ${address}.";

  static String m28(count) => "${count} elementos fallaron";

  static String m29(label, message) => "${label}: ${message}";

  static String m30(name) => "${name} ya está actualizado";

  static String m31(name) => "${name} actualizado";

  static String m32(count) =>
      "${Intl.plural(count, one: '1 grupo', other: '${count} grupos')}";

  static String m33(count) => "${count} sin respuesta";

  static String m34(action) =>
      "Ya lo usa “${action}”. Al guardar, pasará a este.";

  static String m35(modifiers) =>
      "Incluye al menos una de estas teclas: ${modifiers}";

  static String m36(count) =>
      "${Intl.plural(count, one: 'hace 1 hora', other: 'hace ${count} horas')}";

  static String m37(count) => "${Intl.plural(count, other: 'hace ${count} h')}";

  static String m38(target) => "${target} no es una política válida";

  static String m39(proxyName) => "${proxyName} no es un proxy válido";

  static String m40(providerName) =>
      "${providerName} no es un proveedor de proxies válido";

  static String m41(ruleSet) => "${ruleSet} no es un conjunto de reglas válido";

  static String m42(subRule) => "${subRule} no es una SUB_RULE válida";

  static String m43(count) =>
      "${Intl.plural(count, one: '1 elemento', other: '${count} elementos')}";

  static String m44(line, message) => "Línea ${line}: ${message}";

  static String m45(appName) =>
      "1. Abre Ajustes del sistema > Privacidad y seguridad\n2. Elige Servicios de localización\n3. Busca ${appName} en la lista y márcalo\n\nCuando termines, vuelve a la app para continuar. Gracias por tu colaboración.";

  static String m46(label, max) =>
      "${label} debe tener como máximo ${max} caracteres";

  static String m47(size) => "Liberado: ${size}";

  static String m48(count) =>
      "${Intl.plural(count, one: 'hace 1 minuto', other: 'hace ${count} minutos')}";

  static String m49(count) =>
      "${Intl.plural(count, other: 'hace ${count} min')}";

  static String m50(count) =>
      "${Intl.plural(count, one: 'hace 1 mes', other: 'hace ${count} meses')}";

  static String m51(count) => "${Intl.plural(count, other: 'hace ${count} m')}";

  static String m52(code) =>
      "El servidor denegó el acceso (HTTP ${code}). Puede que el enlace haya caducado o que las credenciales sean incorrectas";

  static String m53(code) => "El servidor rechazó la solicitud (HTTP ${code})";

  static String m54(code) =>
      "No se encontró nada en esta dirección (HTTP ${code}). Comprueba que la URL sea correcta";

  static String m55(detail) => "Falló la solicitud de red: ${detail}";

  static String m56(code) =>
      "El servidor tuvo un problema (HTTP ${code}). Inténtalo de nuevo más tarde";

  static String m57(label) => "Aún no hay ningún elemento (${label})";

  static String m58(label, min, max) =>
      "${label} debe estar entre ${min} y ${max}";

  static String m59(label) => "${label} debe ser un número";

  static String m60(label) => "${label} debe estar entre 1024 y 49151";

  static String m61(port) => "Puerto ${port}";

  static String m62(name) => "Perfil ${name} añadido";

  static String m63(days) =>
      "${Intl.plural(days, one: '1 día', other: '${days} días')}";

  static String m64(hours) =>
      "${Intl.plural(hours, one: '1 hora', other: '${hours} horas')}";

  static String m65(total) => "restantes de ${total}";

  static String m66(minutes) =>
      "${Intl.plural(minutes, one: '1 minuto', other: '${minutes} minutos')}";

  static String m67(date) => "hasta el ${date}";

  static String m68(label, profiles) =>
      "${label} sigue en uso en ${profiles}, que dejarán de funcionar correctamente si se elimina. ¿Seguro que quieres eliminarlo?";

  static String m69(count, label) =>
      "${Intl.plural(count, one: '1 proxy', other: '${label} proxies')}";

  static String m70(name, count) => "${name} y otros (${count} proxies)";

  static String m71(removed) =>
      "Se eliminarán estos proxies: ${removed}. Una línea cuyo nombre cambió cuenta como un proxy nuevo, y los perfiles personalizados que mencionen los eliminados los marcarán como ausentes. ¿Aplicar de todos modos?";

  static String m72(removed, added) =>
      "Se eliminarán estos proxies: ${removed}. Se añadirán estos: ${added}. Una línea cuyo nombre cambió cuenta como un proxy nuevo, y los perfiles personalizados que mencionen los eliminados los marcarán como ausentes. ¿Aplicar de todos modos?";

  static String m73(name) =>
      "${name} es el destino MATCH. Elige otro destino antes de desactivarla o eliminarla";

  static String m74(name) =>
      "${name} es el destino de reglas añadidas. Cámbiales el destino antes de desactivarla o eliminarla";

  static String m75(name) => "${name} no está en este perfil";

  static String m76(name) => "${name} ya es un nombre de este perfil";

  static String m77(name) =>
      "${name} toma sus nodos de un proveedor, algo que las cadenas aún no admiten";

  static String m78(name) =>
      "${name} tiene proxies que no pueden conectarse a través de otro salto, como direct";

  static String m79(name) =>
      "El filtro de ${name} usa una sintaxis que la app aún no puede leer";

  static String m80(label) =>
      "${label} sigue mencionado por reglas, grupos de proxies, proxies de marcación, DNS o NTP de este perfil, que dejarán de funcionar si se elimina. ¿Seguro que quieres eliminarlo?";

  static String m81(count, label) =>
      "${Intl.plural(count, one: '1 grupo de proxies', other: '${label} grupos de proxies')}";

  static String m82(count, label) =>
      "${Intl.plural(count, one: '1 regla', other: '${label} reglas')}";

  static String m83(appName) => "${appName} (Modo seguro)";

  static String m84(count) =>
      "${Intl.plural(count, one: '1 segundo', other: '${count} segundos')}";

  static String m85(count) => "${count} en vigor";

  static String m86(count) =>
      "${Intl.plural(count, one: '1 problema', other: '${count} problemas')}";

  static String m87(count) =>
      "${Intl.plural(count, one: '1 ajuste', other: '${count} ajustes')}";

  static String m88(link) => "No se pudo leer ningún proxy de ${link}";

  static String m89(label) => "${label} debe ser un solo elemento";

  static String m90(days) =>
      "Tu suscripción caduca en ${Intl.plural(days, one: '1 día', other: '${days} días')}";

  static String m91(value) => "Pico: ${value}";

  static String m92(value) => "Total: ${value}";

  static String m93(transport) => "Encabezados ${transport}";

  static String m94(label) => "${label} debe ser una URL";

  static String m95(appName) =>
      "No permitiste que ${appName} se conectara como VPN";

  static String m96(count) =>
      "${Intl.plural(count, one: 'hace 1 año', other: 'hace ${count} años')}";

  static String m97(count) => "${Intl.plural(count, other: 'hace ${count} a')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "forkSpeedTest": MessageLookupByLibrary.simpleMessage("Comprobar velocidad"),
    "forkSpeedTestAll": MessageLookupByLibrary.simpleMessage("Comprobar velocidad de todos los nodos"),
    "forkSpeedTestUrl": MessageLookupByLibrary.simpleMessage("Servicio de prueba de velocidad"),
    "forkDirectYandex": MessageLookupByLibrary.simpleMessage("DIRECT siempre usa Yandex Internetometer"),
    "forkSpeedDownloadUrl": MessageLookupByLibrary.simpleMessage("URL de descarga (GET)"),
    "forkSpeedUploadUrl": MessageLookupByLibrary.simpleMessage("URL de subida (POST)"),
    "forkSpeedMbps": MessageLookupByLibrary.simpleMessage("Mbps"),
    "forkSpeedFailed": MessageLookupByLibrary.simpleMessage("Prueba fallida"),
    "forkVeryFast": MessageLookupByLibrary.simpleMessage("Muy rápido"),
    "forkFast": MessageLookupByLibrary.simpleMessage("Rápido"),
    "forkFull": MessageLookupByLibrary.simpleMessage("Completo"),
    "forkVeryFastDesc": MessageLookupByLibrary.simpleMessage("Selección de YouTube, hasta 5 finalistas, detener al llegar a 6/6"),
    "forkFastDesc": MessageLookupByLibrary.simpleMessage("Selección de YouTube, hasta 5 finalistas, dos verificaciones"),
    "forkFullDesc": MessageLookupByLibrary.simpleMessage("Todas las estrategias, dos pruebas completas cada una"),
    "forkTrialError": MessageLookupByLibrary.simpleMessage("Error de inicio o prueba"),
    "forkSuccess": MessageLookupByLibrary.simpleMessage("Correcto"),
    "forkScreenFailed": MessageLookupByLibrary.simpleMessage("Selección fallida"),
    "forkScreenOnly": MessageLookupByLibrary.simpleMessage("Solo selección"),
    "forkPartialSuccess": MessageLookupByLibrary.simpleMessage("Parcialmente correcto"),
    "forkTestFailed": MessageLookupByLibrary.simpleMessage("Prueba fallida"),
    "forkDegraded": MessageLookupByLibrary.simpleMessage("Limitado / latencia alta"),
    "forkNoConnection": MessageLookupByLibrary.simpleMessage("Sin conexión"),
    "forkUnconfirmed": MessageLookupByLibrary.simpleMessage("Sin confirmar"),
    "forkNoResponse": MessageLookupByLibrary.simpleMessage("El servidor no respondió"),
    "forkHighLatency": MessageLookupByLibrary.simpleMessage("Latencia alta"),
    "forkReachable": MessageLookupByLibrary.simpleMessage("Conexión disponible"),
    "forkCoreUnavailable": MessageLookupByLibrary.simpleMessage("Núcleo Mihomo no disponible"),
    "forkNoCoreResponse": MessageLookupByLibrary.simpleMessage("Sin respuesta del núcleo"),
    "forkNoVerifiedResult": MessageLookupByLibrary.simpleMessage("Sin resultado verificado"),
    "forkActiveStrategy": MessageLookupByLibrary.simpleMessage("Estrategia activa"),
    "forkSelectedStrategy": MessageLookupByLibrary.simpleMessage("Estrategia seleccionada"),
    "forkUndefined": MessageLookupByLibrary.simpleMessage("Sin definir"),
    "forkNotSelected": MessageLookupByLibrary.simpleMessage("No seleccionada"),
    "forkHttpsLatency": MessageLookupByLibrary.simpleMessage("Latencia de red · HTTPS"),
    "forkChooseStrategy": MessageLookupByLibrary.simpleMessage("Elegir estrategia Zapret"),
    "forkChecking": MessageLookupByLibrary.simpleMessage("Comprobando"),
    "forkSlow": MessageLookupByLibrary.simpleMessage("Lento"),
    "forkNoReply": MessageLookupByLibrary.simpleMessage("Sin respuesta"),
    "forkUseCache": MessageLookupByLibrary.simpleMessage("Usando lista guardada o incluida"),
    "forkFallbackDownloaded": MessageLookupByLibrary.simpleMessage("Descargado de la fuente alternativa"),
    "forkRetryInterval": MessageLookupByLibrary.simpleMessage("Reintentos automáticos cada 15 minutos"),
    "forkNoUpdate": MessageLookupByLibrary.simpleMessage("Aún no actualizado"),
    "forkDailyOff": MessageLookupByLibrary.simpleMessage("Diario, desactivado por defecto"),
    "forkRealDirect": MessageLookupByLibrary.simpleMessage("Flujo de vídeo real mediante DIRECT"),
    "forkExcludeAuto": MessageLookupByLibrary.simpleMessage("No añadir automáticamente"),
    "forkAllApplied": MessageLookupByLibrary.simpleMessage("Todas las entradas aplicadas en Mihomo"),
    "forkConflict": MessageLookupByLibrary.simpleMessage("Conflicto"),
    "forkConflicts": MessageLookupByLibrary.simpleMessage("Conflictos"),
    "forkSourceMatches": MessageLookupByLibrary.simpleMessage("Coincide con"),
    "forkNextZapretStart": MessageLookupByLibrary.simpleMessage("Se aplica al próximo inicio de Zapret"),
    "forkEngineDebugTip": MessageLookupByLibrary.simpleMessage("La depuración muestra la salida sin procesar de winws/winws2."),
    "forkHttpsInterval": MessageLookupByLibrary.simpleMessage("Intervalo de comprobación HTTPS de Zapret"),
    "forkCoreRecovery": MessageLookupByLibrary.simpleMessage("Recuperar el núcleo tras un fallo"),
    "forkSelectedPingInterval": MessageLookupByLibrary.simpleMessage("Intervalo de comprobación de servidores seleccionados"),
    "forkOtherPingInterval": MessageLookupByLibrary.simpleMessage("Intervalo de comprobación de otros servidores"),
    "forkDisabled": MessageLookupByLibrary.simpleMessage("Desactivado"),
    "forkLogFooter": MessageLookupByLibrary.simpleMessage("Últimos 500 eventos. El archivo local se recopila mientras la aplicación está activa."),
    "forkNoTodayLogs": MessageLookupByLibrary.simpleMessage("No hay registros de hoy"),
    "forkExportLogsFailed": MessageLookupByLibrary.simpleMessage("No se pudieron exportar los registros"),
    "forkTunNotRequested": MessageLookupByLibrary.simpleMessage("No solicitado / VPN desactivada"),
    "forkTunFailure": MessageLookupByLibrary.simpleMessage("El núcleo informa de un fallo TUN"),
    "forkTunNoFailure": MessageLookupByLibrary.simpleMessage("El núcleo no informa de errores TUN (no es una prueba de tráfico)"),
    "forkDriverNotFound": MessageLookupByLibrary.simpleMessage("Controlador no encontrado entre servicios activos"),
    "forkLatestDirect": MessageLookupByLibrary.simpleMessage("Últimos resultados DIRECT, no prueban la interceptación de WinDivert"),
    "forkWinDivertFilters": MessageLookupByLibrary.simpleMessage("Filtros WinDivert"),
    "forkTrafficLists": MessageLookupByLibrary.simpleMessage("Listas de procesamiento de tráfico"),
    "forkTuneModesHint": MessageLookupByLibrary.simpleMessage("Muy rápido, rápido o completo · Mihomo DIRECT"),
    "forkFallbackHint": MessageLookupByLibrary.simpleMessage("Tres comprobaciones fallidas; solo candidatos confirmados; reversión si falla"),
    "forkNoFinalists": MessageLookupByLibrary.simpleMessage("No hay finalistas con puntuación positiva. La preselección se muestra por separado."),
    "forkLiveTopFive": MessageLookupByLibrary.simpleMessage("Las cinco mejores estrategias están resaltadas y ordenadas. Las confirmadas se pueden aplicar."),
    "forkHistoryTopFive": MessageLookupByLibrary.simpleMessage("Las cinco mejores estrategias están resaltadas y ordenadas. El historial es de solo lectura."),
    "forkScoringHint": MessageLookupByLibrary.simpleMessage("Puntuación: funciona = 2, restringido = 1, sin respuesta = 0. Prueba completa: 0–6; preselección: solo YouTube, 0–2. GoogleVideo es adicional. La API de voz de Discord no comprueba el UDP de voz."),
    "forkScreeningHint": MessageLookupByLibrary.simpleMessage("Discord y GoogleVideo no se comprobaron."),
    "forkModeRestartHint": MessageLookupByLibrary.simpleMessage("Si Zapret está en ejecución, el modo se aplica de inmediato mediante un reinicio."),
    "forkAverage": MessageLookupByLibrary.simpleMessage("media"),
    "forkEmptySourceFile": MessageLookupByLibrary.simpleMessage("La fuente devolvió un archivo vacío o demasiado corto"),
    "forkSourceNoEntries": MessageLookupByLibrary.simpleMessage("Actualización rechazada: la fuente no contiene entradas"),
    "forkKeepEmptyTemplate": MessageLookupByLibrary.simpleMessage("Plantilla vacía; se conserva el archivo local"),
    "forkListSizeLimit": MessageLookupByLibrary.simpleMessage("El archivo actualizado supera el límite de 2 MiB"),
    "forkConcurrentEdit": MessageLookupByLibrary.simpleMessage("El archivo cambió durante la descarga; se detuvo la actualización para conservar la edición simultánea"),
    "forkFilesUpdated": MessageLookupByLibrary.simpleMessage("Archivos actualizados"),
    "forkUserFilesKept": MessageLookupByLibrary.simpleMessage("No se sobrescribieron los archivos de usuario (*-user.txt)."),
    "forkRollbackConcurrent": MessageLookupByLibrary.simpleMessage("Edición simultánea detectada; se omitió la reversión automática para conservarla"),
    "forkWriteVerificationFailed": MessageLookupByLibrary.simpleMessage("No se pudo verificar la escritura"),
    "forkRollbackUnconfirmed": MessageLookupByLibrary.simpleMessage("No se pudo confirmar ni revertir por completo el resultado"),
    "forkRollbackRestored": MessageLookupByLibrary.simpleMessage("La actualización no terminó. Los archivos modificados se restauraron automáticamente desde .bak."),
    "forkReinstallHelperQuestion": MessageLookupByLibrary.simpleMessage("¿Reinstalar el servicio Helper?"),
    "forkReinstallHelperHint": MessageLookupByLibrary.simpleMessage("El servicio se sustituirá por la versión de la carpeta actual de FlClashZ. Helper detendrá Mihomo Core y Zapret durante la reinstalación; la VPN y el bypass se interrumpirán temporalmente. Vuelve a iniciarlos tras actualizar. No muevas ni elimines la carpeta FlClashZ después de reinstalar el servicio."),
    "forkHelperReinstalled": MessageLookupByLibrary.simpleMessage("Servicio Helper reinstalado. Catálogo de Zapret2 cargado."),
    "forkWatchdogHint": MessageLookupByLibrary.simpleMessage("Helper recupera el proceso, hasta tres intentos"),
    "forkStartWithMihomo": MessageLookupByLibrary.simpleMessage("Iniciar Zapret con Mihomo"),
    "forkStopWithMihomo": MessageLookupByLibrary.simpleMessage("Zapret también se detiene al detener Mihomo"),
    "forkReinstallHelperDesc": MessageLookupByLibrary.simpleMessage("Actualizar el servicio compartido de Mihomo y Zapret desde la carpeta actual de FlClashZ"),
    "forkAutomaticFromProfile": MessageLookupByLibrary.simpleMessage("Automáticamente desde el perfil"),
    "forkProtectionHint": MessageLookupByLibrary.simpleMessage("hosts, proxies, DNS, fake-ip y route-exclude-address. Las listas se generan por separado; el perfil no cambia."),
    "forkUpdateListsHint": MessageLookupByLibrary.simpleMessage("Descargar listas actuales conservando las entradas locales"),
    "forkReloadListsHint": MessageLookupByLibrary.simpleMessage("Recargar archivos del disco"),
    "forkListsFooter": MessageLookupByLibrary.simpleMessage("Se actualizan cuatro listas principales. Se conservan los archivos de usuario (*-user.txt). Se crea .bak antes de escribir. Reinicia Zapret después de los cambios. No se actualizan youtube-bad-nodes.txt ni list-auto.txt."),
    "forkSmartHostsHint": MessageLookupByLibrary.simpleMessage("Usa Hosts de Mihomo. No cambia el archivo hosts de Windows ni la configuración DNS. Las entradas del perfil y manuales tienen prioridad."),
    "forkMalwHint": MessageLookupByLibrary.simpleMessage("DNS + proxy SNI para servicios con bloqueo por IP (ChatGPT, Spotify, Twitch, etc.)"),
    "forkGeoHideHint": MessageLookupByLibrary.simpleMessage("Hosts de GeoHide: IP y proxies para servicios bloqueados"),
    "forkYoutubeListHint": MessageLookupByLibrary.simpleMessage("Las CDN problemáticas de la lista Zapret2 GUI se redirigen a 127.0.0.2"),
    "forkCdnFast": MessageLookupByLibrary.simpleMessage("Rápido"),
    "forkCdnHint": MessageLookupByLibrary.simpleMessage("Las mediciones usan URL firmadas de vídeo y hasta 3 MiB por nodo. Los resultados desconocidos no generan bloqueos. Las mediciones antiguas caducan automáticamente."),
    "forkCdnProcessChanged": MessageLookupByLibrary.simpleMessage("La estrategia cambió durante la comprobación; se descartó el resultado"),
    "forkCdnCheckBusy": MessageLookupByLibrary.simpleMessage("Comprobación en curso"),
    "forkCdnProbeBusy": MessageLookupByLibrary.simpleMessage("Sin ranura disponible o tiempo agotado"),
    "forkDirectUnconfirmed": MessageLookupByLibrary.simpleMessage("Ruta DIRECT no confirmada"),
    "forkCdnWatchHttp": MessageLookupByLibrary.simpleMessage("Error de la página de YouTube"),
    "forkCdnNoStreamUrls": MessageLookupByLibrary.simpleMessage("YouTube no devolvió enlaces directos de vídeo"),
    "forkCdnStreamUrls": MessageLookupByLibrary.simpleMessage("Enlaces de vídeo obtenidos"),
    "forkCdnLocalMapping": MessageLookupByLibrary.simpleMessage("El nodo ya apunta a una dirección local"),
    "forkCdnRedirectRejected": MessageLookupByLibrary.simpleMessage("Redirección de CDN rechazada"),
    "forkCdnStreamHttp": MessageLookupByLibrary.simpleMessage("Error de respuesta de CDN"),
    "forkCdnNotMedia": MessageLookupByLibrary.simpleMessage("La CDN no devolvió contenido multimedia"),
    "forkCdnInsufficientSample": MessageLookupByLibrary.simpleMessage("Muestra insuficiente para medir"),
    "forkCdnBudgetExhausted": MessageLookupByLibrary.simpleMessage("Tiempo total de comprobación agotado"),
    "forkCdnNoMeasurements": MessageLookupByLibrary.simpleMessage("Sin mediciones fiables; listas sin cambios"),
    "forkCdnMeasured": MessageLookupByLibrary.simpleMessage("Medidos"),
    "forkControlRun": MessageLookupByLibrary.simpleMessage("Verificación"),
    "forkTuneRequirements": MessageLookupByLibrary.simpleMessage("Se requiere el núcleo Mihomo conectado y un catálogo de estrategias."),
    "forkPreparing": MessageLookupByLibrary.simpleMessage("Preparando"),
    "forkEngineChanged": MessageLookupByLibrary.simpleMessage("El motor se detuvo o cambió de PID durante la comprobación"),
    "forkEngineExited": MessageLookupByLibrary.simpleMessage("El motor terminó durante la comprobación"),
    "forkTuneInterrupted": MessageLookupByLibrary.simpleMessage("Prueba interrumpida; se conservaron los resultados anteriores"),
    "forkTuneEarlyStop": MessageLookupByLibrary.simpleMessage("Se obtuvo 6/6; la prueba terminó antes de tiempo"),
    "forkHistorySaveFailed": MessageLookupByLibrary.simpleMessage("No se pudo guardar el historial de autoajuste"),
    "forkTuneSaveFailed": MessageLookupByLibrary.simpleMessage("No se pudieron guardar los resultados de autoajuste"),
    "forkRestoreStateFailed": MessageLookupByLibrary.simpleMessage("No se pudo restaurar el estado original"),
    "forkAdditional": MessageLookupByLibrary.simpleMessage("adicional"),
    "forkLastError": MessageLookupByLibrary.simpleMessage("Último error"),
    "forkStrategyLaunchFailed": MessageLookupByLibrary.simpleMessage("No se pudo iniciar la estrategia"),
    "forkHelperBusy": MessageLookupByLibrary.simpleMessage("Helper no disponible durante una operación de Zapret; vuelve a intentarlo cuando termine"),
    "forkCoreNotApplied": MessageLookupByLibrary.simpleMessage("La configuración de Mihomo aún no se ha aplicado"),
    "forkCoreProtectionMissing": MessageLookupByLibrary.simpleMessage("No hay configuración confirmada de Mihomo para proteger Zapret"),
    "forkStopUnconfirmed": MessageLookupByLibrary.simpleMessage("Helper no disponible: no se confirmó la detención de Zapret"),
    "forkStopPending": MessageLookupByLibrary.simpleMessage("La operación de Zapret no terminó después de detenerlo"),
    "forkStillRunning": MessageLookupByLibrary.simpleMessage("Zapret sigue ejecutándose"),
    "forkCoreBusy": MessageLookupByLibrary.simpleMessage("Espera a que termine la operación actual de Mihomo"),
    "forkCoreRecoveryFailed": MessageLookupByLibrary.simpleMessage("No se pudo recuperar Mihomo tras comprobar o actualizar Helper"),
    "forkCoreRecoveredZapretStopped": MessageLookupByLibrary.simpleMessage("Mihomo se recuperó, pero Zapret no arrancó"),
    "forkHelperCheckedZapretStopped": MessageLookupByLibrary.simpleMessage("Helper comprobado, pero Zapret no arrancó"),
    "forkHelperCheckedStartCore": MessageLookupByLibrary.simpleMessage("Helper comprobado. Inicia Mihomo antes de Zapret"),
    "forkLaunchUnavailable": MessageLookupByLibrary.simpleMessage("Zapret no puede iniciarse ahora"),
    "forkHelperUpdatedCatalogMissing": MessageLookupByLibrary.simpleMessage("Helper actualizado, pero el catálogo Zapret2 aún no está disponible"),
    "forkHelperUnavailableReinstall": MessageLookupByLibrary.simpleMessage("Helper no disponible. Reinicia el cliente y comprueba la instalación del servicio."),
    "forkInvalidGithubResponse": MessageLookupByLibrary.simpleMessage("Respuesta de GitHub no válida"),
    "forkInvalidSourceEntries": MessageLookupByLibrary.simpleMessage("La fuente no contiene entradas válidas"),
    "forkPrimarySource": MessageLookupByLibrary.simpleMessage("Principal"),
    "forkBackupSource": MessageLookupByLibrary.simpleMessage("Alternativa"),
    "forkCustomSourceValidation": MessageLookupByLibrary.simpleMessage("Se necesita un nombre único y una URL HTTPS sin credenciales"),
    "forkHttpsOnly": MessageLookupByLibrary.simpleMessage("Solo se permiten fuentes HTTPS"),
    "forkEmptyResponse": MessageLookupByLibrary.simpleMessage("Respuesta vacía"),
    "forkInvalidRedirect": MessageLookupByLibrary.simpleMessage("Redirección no válida"),
    "forkSourceTooLarge": MessageLookupByLibrary.simpleMessage("La fuente supera 10 MiB"),
    "forkTooManyRedirects": MessageLookupByLibrary.simpleMessage("Demasiadas redirecciones"),
    "forkArchiveSaved": MessageLookupByLibrary.simpleMessage("Archivo guardado"),
    "forkExportServiceJournal": MessageLookupByLibrary.simpleMessage("Exportar registro del servicio"),
    "forkJournalUnavailable": MessageLookupByLibrary.simpleMessage("Registro del servicio no disponible"),
    "forkSaveDiagnosticReport": MessageLookupByLibrary.simpleMessage("Guardar informe de diagnóstico"),
    "forkReportSaveFailed": MessageLookupByLibrary.simpleMessage("No se pudo guardar el informe"),
    "forkRestartAll": MessageLookupByLibrary.simpleMessage("Reiniciar todo"),
    "forkRestartAllTip": MessageLookupByLibrary.simpleMessage("¿Comprobar Helper y reiniciar Mihomo y Zapret? Se restaurarán según el estado anterior y el inicio vinculado."),
    "forkDiagnostics": MessageLookupByLibrary.simpleMessage("Diagnóstico"),
    "forkRunDiagnostics": MessageLookupByLibrary.simpleMessage("Ejecutar diagnóstico"),
    "forkCopyReport": MessageLookupByLibrary.simpleMessage("Copiar informe"),
    "forkResults": MessageLookupByLibrary.simpleMessage("Resultados"),
    "forkCheckFailed": MessageLookupByLibrary.simpleMessage("Error de comprobación"),
    "forkPassed": MessageLookupByLibrary.simpleMessage("Verificado"),
    "forkUnavailable": MessageLookupByLibrary.simpleMessage("No disponible"),
    "forkRunning": MessageLookupByLibrary.simpleMessage("En ejecución"),
    "forkStopped": MessageLookupByLibrary.simpleMessage("Detenido"),
    "forkStrategies": MessageLookupByLibrary.simpleMessage("Estrategias"),
    "forkComponentIntegrity": MessageLookupByLibrary.simpleMessage("Integridad de componentes / WinDivert"),
    "forkMissingDamaged": MessageLookupByLibrary.simpleMessage("Faltan o están dañados"),
    "forkSettingsJson": MessageLookupByLibrary.simpleMessage("Ajustes (JSON)"),
    "forkSystemProxy": MessageLookupByLibrary.simpleMessage("Proxy del sistema"),
    "forkServiceJournal": MessageLookupByLibrary.simpleMessage("Registro del servicio"),
    "forkNetworkChecks": MessageLookupByLibrary.simpleMessage("Comprobaciones de red"),
    "forkZapretLogs": MessageLookupByLibrary.simpleMessage("Registros de Zapret"),
    "forkHelperJournal": MessageLookupByLibrary.simpleMessage("Registro de Helper"),
    "forkFilter": MessageLookupByLibrary.simpleMessage("Filtro"),
    "forkAllEvents": MessageLookupByLibrary.simpleMessage("Todos los eventos"),
    "forkInfo": MessageLookupByLibrary.simpleMessage("Información"),
    "forkErrors": MessageLookupByLibrary.simpleMessage("Errores"),
    "forkStderr": MessageLookupByLibrary.simpleMessage("Salida stderr"),
    "forkDebug": MessageLookupByLibrary.simpleMessage("Depuración"),
    "forkLogReadError": MessageLookupByLibrary.simpleMessage("Error al leer el registro"),
    "forkLocalLogs": MessageLookupByLibrary.simpleMessage("Registros locales"),
    "forkOpenZapretLogs": MessageLookupByLibrary.simpleMessage("Abrir carpeta de registros de Zapret"),
    "forkExportTodayLogs": MessageLookupByLibrary.simpleMessage("Exportar registros de hoy (ZIP)"),
    "forkSidebarSpeed": MessageLookupByLibrary.simpleMessage("Velocidad"),
    "forkSidebarSession": MessageLookupByLibrary.simpleMessage("Durante la sesión"),
    "forkSidebar24Hours": MessageLookupByLibrary.simpleMessage("Últimas 24 horas"),
    "forkCrashHistory": MessageLookupByLibrary.simpleMessage("Historial de fallos y watchdog"),
    "forkEvents": MessageLookupByLibrary.simpleMessage("Eventos"),
    "forkNoEvents": MessageLookupByLibrary.simpleMessage("Sin eventos"),
    "forkAutoTuneOnFailureWithoutResults": MessageLookupByLibrary.simpleMessage("Ajuste automático sin resultados confirmados"),
    "forkRetuneOnFailure": MessageLookupByLibrary.simpleMessage("Repetir el ajuste automático si falla"),
    "forkAutoTuneMode": MessageLookupByLibrary.simpleMessage("Modo de ajuste automático"),
    "forkState": MessageLookupByLibrary.simpleMessage("Estado"),
    "forkStarted": MessageLookupByLibrary.simpleMessage("Iniciado"),
    "forkStopZapret": MessageLookupByLibrary.simpleMessage("Detener Zapret"),
    "forkStartZapret": MessageLookupByLibrary.simpleMessage("Iniciar Zapret"),
    "forkRestartZapret": MessageLookupByLibrary.simpleMessage("Reiniciar Zapret"),
    "forkStrategy": MessageLookupByLibrary.simpleMessage("Estrategia"),
    "forkSelectedMode": MessageLookupByLibrary.simpleMessage("Modo seleccionado"),
    "forkEngineProcess": MessageLookupByLibrary.simpleMessage("Motor y proceso"),
    "forkHelperError": MessageLookupByLibrary.simpleMessage("Error de Helper"),
    "forkRefreshStatus": MessageLookupByLibrary.simpleMessage("Actualizar estado"),
    "forkAutoTune": MessageLookupByLibrary.simpleMessage("Ajuste automático de estrategias"),
    "forkStartAutoTune": MessageLookupByLibrary.simpleMessage("Iniciar ajuste automático"),
    "forkCancelTest": MessageLookupByLibrary.simpleMessage("Cancelar prueba"),
    "forkTestResult": MessageLookupByLibrary.simpleMessage("Resultado de prueba"),
    "forkAutoTuneHistory": MessageLookupByLibrary.simpleMessage("Historial de ajuste automático"),
    "forkLastThirtyRuns": MessageLookupByLibrary.simpleMessage("Últimas 30 pruebas completadas"),
    "forkAutoFallback": MessageLookupByLibrary.simpleMessage("Estrategia de respaldo automática"),
    "forkCheckNow": MessageLookupByLibrary.simpleMessage("Comprobar ahora"),
    "forkEmptyHistory": MessageLookupByLibrary.simpleMessage("El historial está vacío"),
    "forkPreviousRun": MessageLookupByLibrary.simpleMessage("Prueba guardada anterior"),
    "forkCompletedWithError": MessageLookupByLibrary.simpleMessage("Completado con error"),
    "forkApplyStrategy": MessageLookupByLibrary.simpleMessage("¿Aplicar estrategia?"),
    "forkTuneResults": MessageLookupByLibrary.simpleMessage("Resultados del ajuste automático"),
    "forkSmartHosts": MessageLookupByLibrary.simpleMessage("Hosts inteligente"),
    "forkManagement": MessageLookupByLibrary.simpleMessage("Gestión"),
    "forkEnableSmartHosts": MessageLookupByLibrary.simpleMessage("Activar Hosts inteligente"),
    "forkAutoUpdate": MessageLookupByLibrary.simpleMessage("Actualización automática"),
    "forkUpdateInterval": MessageLookupByLibrary.simpleMessage("Intervalo de actualización"),
    "forkUpdateNow": MessageLookupByLibrary.simpleMessage("Actualizar ahora"),
    "forkSources": MessageLookupByLibrary.simpleMessage("Fuentes"),
    "forkAdBlock": MessageLookupByLibrary.simpleMessage("Bloqueo de anuncios"),
    "forkCustomHttpsSources": MessageLookupByLibrary.simpleMessage("Fuentes HTTPS personalizadas"),
    "forkYouTubeOptimization": MessageLookupByLibrary.simpleMessage("Optimización de YouTube"),
    "forkCommunityList": MessageLookupByLibrary.simpleMessage("Usar lista comunitaria"),
    "forkSlowCdn": MessageLookupByLibrary.simpleMessage("Bloquear CDN lentas medidas"),
    "forkAutoCdn": MessageLookupByLibrary.simpleMessage("Prueba automática de velocidad CDN"),
    "forkSpeedThreshold": MessageLookupByLibrary.simpleMessage("Umbral de velocidad"),
    "forkRetention": MessageLookupByLibrary.simpleMessage("Retención de mediciones"),
    "forkCheckCdn": MessageLookupByLibrary.simpleMessage("Comprobar velocidad CDN"),
    "forkResetMeasurements": MessageLookupByLibrary.simpleMessage("Restablecer mediciones"),
    "forkReceivedHosts": MessageLookupByLibrary.simpleMessage("Hosts recibidos"),
    "forkExclusions": MessageLookupByLibrary.simpleMessage("Exclusiones"),
    "forkViewAutoHosts": MessageLookupByLibrary.simpleMessage("Ver entradas automáticas"),
    "forkViewAppliedHosts": MessageLookupByLibrary.simpleMessage("Ver Hosts aplicados"),
    "forkAppliedHosts": MessageLookupByLibrary.simpleMessage("Hosts aplicados"),
    "forkOnlyConflicts": MessageLookupByLibrary.simpleMessage("Solo conflictos"),
    "forkUnknownSource": MessageLookupByLibrary.simpleMessage("Fuente no confirmada"),
    "forkManualHosts": MessageLookupByLibrary.simpleMessage("Hosts manuales"),
    "forkProfileScript": MessageLookupByLibrary.simpleMessage("Perfil / script"),
    "forkHelperService": MessageLookupByLibrary.simpleMessage("Servicio Helper"),
    "forkReinstallHelper": MessageLookupByLibrary.simpleMessage("Reinstalar Helper"),
    "forkMihomoProtection": MessageLookupByLibrary.simpleMessage("Protección de conexiones de Mihomo"),
    "forkExcludedIps": MessageLookupByLibrary.simpleMessage("IP y subredes excluidas"),
    "forkExcludedDomains": MessageLookupByLibrary.simpleMessage("Dominios excluidos"),
    "forkRefreshExclusions": MessageLookupByLibrary.simpleMessage("Actualizar exclusiones"),
    "forkZapretLists": MessageLookupByLibrary.simpleMessage("Listas de Zapret"),
    "forkListFile": MessageLookupByLibrary.simpleMessage("Archivo de lista"),
    "forkEditList": MessageLookupByLibrary.simpleMessage("Editar lista"),
    "forkUpdateLists": MessageLookupByLibrary.simpleMessage("Actualizar listas"),
    "forkReloadLists": MessageLookupByLibrary.simpleMessage("Recargar listas"),
    "forkVerboseEngine": MessageLookupByLibrary.simpleMessage("Salida detallada del motor"),
    "forkResetSettings": MessageLookupByLibrary.simpleMessage("Restablecer ajustes"),
    "forkMode": MessageLookupByLibrary.simpleMessage("Modo"),
    "forkProcessingMode": MessageLookupByLibrary.simpleMessage("Modo de procesamiento"),
    "forkZapretStrategies": MessageLookupByLibrary.simpleMessage("Estrategias de Zapret"),
    "forkCatalogUnavailable": MessageLookupByLibrary.simpleMessage("Catálogo de estrategias no disponible"),
    "forkSaveSettingsFailed": MessageLookupByLibrary.simpleMessage("No se pudieron guardar los ajustes"),
    "about": MessageLookupByLibrary.simpleMessage("Acerca de"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Control de acceso"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Solo las apps seleccionadas usan la VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "El control de acceso elige qué apps usan el proxy.",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "El control de acceso de apps está desactivado",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Las apps seleccionadas quedan excluidas de la VPN",
    ),
    "accessControlSelectedCount": m0,
    "accessControlSettings": MessageLookupByLibrary.simpleMessage(
      "Ajustes de control de acceso",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Cuenta"),
    "action": MessageLookupByLibrary.simpleMessage("Acción"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage(
      "Probar la latencia de todos",
    ),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("Modo directo"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("Modo global"),
    "actionMode": MessageLookupByLibrary.simpleMessage("Cambiar modo"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("Proxy del sistema"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("Modo regla"),
    "actionStart": MessageLookupByLibrary.simpleMessage("Iniciar/Detener"),
    "actionTun": MessageLookupByLibrary.simpleMessage("TUN"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage(
      "Actualizar perfiles",
    ),
    "actionView": MessageLookupByLibrary.simpleMessage("Mostrar/Ocultar"),
    "add": MessageLookupByLibrary.simpleMessage("Añadir"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("Añadir proxy"),
    "addFilters": MessageLookupByLibrary.simpleMessage("Añadir filtros"),
    "addFromClipboard": MessageLookupByLibrary.simpleMessage(
      "Añadir desde el portapapeles",
    ),
    "addNodes": MessageLookupByLibrary.simpleMessage("Añadir nodos"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage(
      "Añadir entrada de sobrescritura",
    ),
    "addProfile": MessageLookupByLibrary.simpleMessage("Añadir perfil"),
    "addProxyChain": MessageLookupByLibrary.simpleMessage("Añadir cadena"),
    "addProxyChainHop": MessageLookupByLibrary.simpleMessage("Añadir salto"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Añadir grupo de proxies",
    ),
    "addRule": MessageLookupByLibrary.simpleMessage("Añadir regla"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("Añadir ajuste"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Añadir SSID"),
    "addToLocalProxies": MessageLookupByLibrary.simpleMessage(
      "Añadir a proxies locales",
    ),
    "addedRules": MessageLookupByLibrary.simpleMessage("Reglas añadidas"),
    "addedToLocalProxies": m1,
    "additionalParameters": MessageLookupByLibrary.simpleMessage(
      "Parámetros adicionales",
    ),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage(
      "Prefijo del nombre",
    ),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage(
      "Sufijo del nombre",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Dirección"),
    "advancedConfig": MessageLookupByLibrary.simpleMessage(
      "Configuración avanzada",
    ),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "La configuración avanzada incluye la red, el DNS, las reglas añadidas y los scripts.",
    ),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage(
      "Perfil cifrado",
    ),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage(
      "Clave secreta de age",
    ),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "Este perfil está cifrado con age y necesita una clave secreta de age para descifrarse",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Acepto"),
    "allReferencedProxies": MessageLookupByLibrary.simpleMessage(
      "Todos los proxies referenciados",
    ),
    "allReferencedProxyProviders": MessageLookupByLibrary.simpleMessage(
      "Todos los proveedores de proxies referenciados",
    ),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Permitir que las apps eludan la VPN",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Permitir LAN"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("IP permitidas"),
    "alreadyInLocalProxies": m2,
    "announcement": MessageLookupByLibrary.simpleMessage("Anuncio"),
    "answers": MessageLookupByLibrary.simpleMessage("Respuestas"),
    "app": MessageLookupByLibrary.simpleMessage("App"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "Control de acceso de apps",
    ),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage(
      "No hay proxies locales",
    ),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage(
      "Añadir DNS del sistema",
    ),
    "applied": MessageLookupByLibrary.simpleMessage("Aplicado"),
    "applyNow": MessageLookupByLibrary.simpleMessage("Aplicar ahora"),
    "authentication": MessageLookupByLibrary.simpleMessage("Autenticación"),
    "authenticationDesc": MessageLookupByLibrary.simpleMessage(
      "La autenticación pide usuario y contraseña en el puerto del proxy local.",
    ),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "El proxy del sistema no se aplica mientras la autenticación esté activada.",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("Autorizar"),
    "authorized": MessageLookupByLibrary.simpleMessage("Autorizado"),
    "auto": MessageLookupByLibrary.simpleMessage("Automático"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Buscar actualizaciones automáticamente",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Cerrar conexiones automáticamente",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Cerrar conexiones automáticamente corta las conexiones abiertas al cambiar de proxy.",
    ),
    "autoInclude": MessageLookupByLibrary.simpleMessage(
      "Incluir automáticamente",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Inicio automático"),
    "autoRun": MessageLookupByLibrary.simpleMessage("Ejecución automática"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "La ejecución automática inicia el proxy al abrir la app.",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Configurar DNS del sistema automáticamente",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage(
      "Actualización automática",
    ),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Intervalo de actualización automática",
    ),
    "back": MessageLookupByLibrary.simpleMessage("Atrás"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Información básica"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage(
      "Estrategias básicas",
    ),
    "batchAdd": MessageLookupByLibrary.simpleMessage("Añadir en lote"),
    "batchImport": MessageLookupByLibrary.simpleMessage("Importar en lote"),
    "batchListInputTip": MessageLookupByLibrary.simpleMessage(
      "Un elemento por línea, o separados por comas",
    ),
    "batchMapInputTip": MessageLookupByLibrary.simpleMessage(
      "Una entrada por línea: clave, un espacio y el valor",
    ),
    "batchPreviewTip": m3,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage(
      "Una URL por línea",
    ),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Ignorar la optimización de batería mantiene la app en ejecución en segundo plano.",
    ),
    "beta": MessageLookupByLibrary.simpleMessage("Beta"),
    "bind": MessageLookupByLibrary.simpleMessage("Vincular"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("Modo lista negra"),
    "blockConnection": MessageLookupByLibrary.simpleMessage(
      "Bloquear conexión",
    ),
    "brightness": MessageLookupByLibrary.simpleMessage("Brillo"),
    "buyPlan": MessageLookupByLibrary.simpleMessage("Renovar suscripción"),
    "buyTraffic": MessageLookupByLibrary.simpleMessage("Comprar tráfico"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Dominios excluidos"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Los dominios excluidos solo se aplican mientras el proxy del sistema esté activado.",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "Omitir direcciones privadas",
    ),
    "bypassPrivateRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Con Omitir direcciones privadas activado, las direcciones de LAN, loopback y multidifusión no pasan por TUN.",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("Caché"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage(
      "Algoritmo de caché",
    ),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "La caché está dañada. ¿Borrarla?",
    ),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("Tamaño de caché"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Permite el acceso a la cámara en los ajustes del sistema para escanear códigos QR, o elige una imagen de código QR del álbum.",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Se requiere permiso de cámara",
    ),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage(
      "Cámara no disponible",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancelar"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage(
      "Deseleccionar todo",
    ),
    "cannotSave": MessageLookupByLibrary.simpleMessage("No se puede guardar"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "No se pudo cambiar de proxy; se ha restaurado la selección anterior",
    ),
    "changeServer": MessageLookupByLibrary.simpleMessage("Cambiar de servidor"),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage(
      "Cambios incompatibles",
    ),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("Novedades"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("Correcciones"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("Rendimiento"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("Reversiones"),
    "checkUpdate": MessageLookupByLibrary.simpleMessage(
      "Buscar actualizaciones",
    ),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "La app ya está actualizada",
    ),
    "cipher": MessageLookupByLibrary.simpleMessage("Cifrado"),
    "clearData": MessageLookupByLibrary.simpleMessage("Borrar datos"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "Esto elimina todos los perfiles, ajustes y datos locales, y luego cierra la app. Ábrela de nuevo para empezar de cero.",
    ),
    "clearDataFailed": m4,
    "clearDnsCache": MessageLookupByLibrary.simpleMessage(
      "Borrar la caché DNS",
    ),
    "clearDnsCacheFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo borrar la caché DNS",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Borrar búsqueda"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "Huella del cliente",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage(
      "Exportar al portapapeles",
    ),
    "clipboardImport": MessageLookupByLibrary.simpleMessage(
      "Importar desde el portapapeles",
    ),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo copiar al portapapeles. Puede que la selección sea demasiado grande",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
    "closeConnections": MessageLookupByLibrary.simpleMessage(
      "Cerrar conexiones",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Color"),
    "colorStyle": MessageLookupByLibrary.simpleMessage("Estilo de color"),
    "compact": MessageLookupByLibrary.simpleMessage("Compacto"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirmar"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres borrar todos los datos?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres eliminar este grupo de proxies?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres salir de la ventana actual?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres forzar el fallo del núcleo?",
    ),
    "congestionControl": MessageLookupByLibrary.simpleMessage(
      "Control de congestión",
    ),
    "congestionController": MessageLookupByLibrary.simpleMessage(
      "Control de congestión TCP",
    ),
    "congestionControllerDesc": MessageLookupByLibrary.simpleMessage(
      "El control de congestión TCP solo funciona con la pila mips.",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Conectado"),
    "connecting": MessageLookupByLibrary.simpleMessage("Conectando…"),
    "connection": MessageLookupByLibrary.simpleMessage("Conexión"),
    "connectionStats": MessageLookupByLibrary.simpleMessage(
      "Estadísticas de conexión",
    ),
    "connectionStatsDesc": MessageLookupByLibrary.simpleMessage(
      "Conexiones activas, solicitudes recientes y consultas DNS",
    ),
    "connections": MessageLookupByLibrary.simpleMessage("Conexiones"),
    "connectivity": MessageLookupByLibrary.simpleMessage("Conectividad: "),
    "content": MessageLookupByLibrary.simpleMessage("Contenido"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage(
      "El contenido no puede estar vacío",
    ),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Controlar las reglas añadidas globales",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copiar"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Copiar variables de entorno",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copiar enlace"),
    "copySuccess": MessageLookupByLibrary.simpleMessage(
      "Copiado correctamente",
    ),
    "core": MessageLookupByLibrary.simpleMessage("Núcleo"),
    "coreBlockedByPolicyTip": m5,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Smart App Control de Windows bloqueó FlClashCore.exe porque no está firmado. Abre Seguridad de Windows → Control de aplicaciones y navegador → Configuración de Smart App Control, elige Desactivado y vuelve a iniciar FlClashX. Smart App Control no se puede volver a activar sin reinstalar Windows.",
    ),
    "coreRestartByCommandFailed": MessageLookupByLibrary.simpleMessage(
      "El comando no pudo reiniciar el núcleo",
    ),
    "coreRestartedByCommand": MessageLookupByLibrary.simpleMessage(
      "Núcleo reiniciado por un comando",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Estado del núcleo"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("Fallo detectado"),
    "crashDetectedTip": m6,
    "crashTest": MessageLookupByLibrary.simpleMessage("Prueba de fallo"),
    "create": MessageLookupByLibrary.simpleMessage("Crear"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Fecha de creación"),
    "currentOutboundDesc": MessageLookupByLibrary.simpleMessage(
      "Contiene el botón de inicio y no se puede quitar",
    ),
    "custom": MessageLookupByLibrary.simpleMessage("Personalizado"),
    "customColor": MessageLookupByLibrary.simpleMessage("Color personalizado"),
    "customImportDroppedSubRules": m7,
    "customIssueCoreRejected": m8,
    "customIssueDialerLoop": m9,
    "customIssueDuplicateName": m10,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage(
      "El nombre está vacío",
    ),
    "customIssueGroupLoop": m11,
    "customIssueInvalidEmptyFallback": m12,
    "customIssueInvalidFilter": m13,
    "customIssueMissingDialer": m14,
    "customIssueMissingProviders": m15,
    "customIssueMissingProxies": m16,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "No hay proxies ni proveedores de proxies seleccionados, por lo que el núcleo rechaza este grupo",
    ),
    "customIssueReservedName": m17,
    "customIssuesSummary": m18,
    "customProfile": MessageLookupByLibrary.simpleMessage("Personalizado"),
    "customProfileResources": MessageLookupByLibrary.simpleMessage(
      "Recursos de perfil personalizado",
    ),
    "customProfileResourcesDesc": MessageLookupByLibrary.simpleMessage(
      "Los recursos de perfil personalizado son los proxies, proveedores de reglas, filtros y conjuntos de iconos que añades tú para usarlos en perfiles personalizados.",
    ),
    "cut": MessageLookupByLibrary.simpleMessage("Cortar"),
    "dark": MessageLookupByLibrary.simpleMessage("Oscuro"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Panel"),
    "dashboardAddableSection": MessageLookupByLibrary.simpleMessage(
      "Disponibles para añadir",
    ),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "No se pudo guardar el cambio; se ha revertido",
    ),
    "daysAgo": m19,
    "daysAgoShort": m20,
    "defaultSelected": MessageLookupByLibrary.simpleMessage(
      "Selección predeterminada",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("Predeterminado"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "La configuración debe ser un mapa YAML con un nombre y un tipo",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("Latencia"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("Fallido"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Prueba de latencia"),
    "delayTestAll": MessageLookupByLibrary.simpleMessage(
      "Probar todas las latencias",
    ),
    "delayTestTimeout": MessageLookupByLibrary.simpleMessage(
      "Tiempo de espera de la prueba de latencia",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Eliminar"),
    "deleteMultipTip": m21,
    "deleteTip": m22,
    "desc": MessageLookupByLibrary.simpleMessage(
      "Un cliente proxy multiplataforma basado en Mihomo, sencillo de usar, de código abierto y sin anuncios.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Destino"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "GeoIP de destino",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage(
      "ASN de la IP de destino",
    ),
    "details": m23,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Usa una API de terceros: ipinfo.io",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Modo desarrollador"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "El modo desarrollador está activado.",
    ),
    "deviceIdNotSent": MessageLookupByLibrary.simpleMessage(
      "La suscripción requiere un HWID, pero la aplicación no lo envió. Activa el envío de HWID en los ajustes del perfil.",
    ),
    "deviceIdUnsupported": MessageLookupByLibrary.simpleMessage(
      "La suscripción requiere un HWID, pero esta plataforma no puede proporcionarlo.",
    ),
    "deviceIdUnsupportedTitle": MessageLookupByLibrary.simpleMessage(
      "HWID no compatible",
    ),
    "deviceLimitReached": MessageLookupByLibrary.simpleMessage(
      "Límite de dispositivos alcanzado",
    ),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("Proxy de marcación"),
    "dialerProxyDesc": MessageLookupByLibrary.simpleMessage(
      "El proxy de marcación es la salida que se usa para llegar al servidor NTP.",
    ),
    "dialerProxyLoopStopped": m24,
    "direct": MessageLookupByLibrary.simpleMessage("Directo"),
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage(
      "Desactivar reenvío ICMP",
    ),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "Con el reenvío ICMP desactivado, TUN responde él mismo al ping, por lo que ping ya no muestra la latencia real.",
    ),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage(
      "Desactivar keep-alive TCP",
    ),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Desactivar UDP"),
    "disabled": MessageLookupByLibrary.simpleMessage("Desactivado"),
    "discardChanges": MessageLookupByLibrary.simpleMessage(
      "¿Descartar los cambios?",
    ),
    "disclaimer": MessageLookupByLibrary.simpleMessage("Aviso legal"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "FlClashZ es un cliente gratuito y de código abierto basado en FlClashX, que utiliza el núcleo Mihomo y los componentes Zapret2 y Flowseal. A continuación se describe brevemente qué hace, qué no hace y cómo trata los datos. Al seleccionar «Acepto», aceptas estas condiciones.",
    ),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "El código fuente de FlClashZ es abierto y se distribuye bajo la licencia GPL-3.0. La aplicación es una bifurcación de FlClashX.\n\nEl núcleo Mihomo, Zapret2, Flowseal y otros componentes de terceros se distribuyen conforme a sus respectivas licencias. Los autores no se responsabilizan de las compilaciones modificadas o distribuidas por terceros.",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage("Licencia"),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "La aplicación no incluye sistemas de análisis, telemetría, módulos publicitarios ni envío automático de informes de fallos a sus desarrolladores.\n\nLos desarrolladores de la aplicación no recopilan las URL de suscripciones, el contenido de las configuraciones, información sobre servidores, sitios visitados, conexiones, tráfico ni registros.",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage("Privacidad y datos"),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "Tú decides si usar la aplicación es legal en tu país y eres responsable de lo que hagas con ella.\n\nLa aplicación se ofrece «tal cual», sin garantía alguna. Los desarrolladores no responden por daños derivados de su uso o de la imposibilidad de usarla, ni por suscripciones, configuraciones y enlaces de terceros.",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "Responsabilidad",
    ),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "La aplicación gestiona configuraciones, dirige el tráfico de red según las reglas especificadas y ofrece herramientas para eludir las restricciones de DPI en tu dispositivo.\n\nNo vendemos nada ni proporcionamos servidores proxy, nodos, suscripciones o acceso a la red. Todos los servidores y suscripciones proceden de proveedores externos, con quienes debes resolver las cuestiones de legalidad, seguridad y calidad. La aplicación no está afiliada a dichos proveedores ni es responsable de ellos.",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage(
      "Qué es y qué no es",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("Desconectado"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "Nueva versión disponible",
    ),
    "dnsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "Caché DNS borrada",
    ),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "Sin esta entrada, TUN secuestra todas las consultas DNS al puerto 53 (any:53).",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("Secuestro de DNS"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("Modo DNS"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Las entradas añadidas aquí sustituyen el DNS de todos los perfiles de URL y de archivo; lo que no añadas conserva el ajuste del propio perfil. Los perfiles personalizados definen su DNS en su contenido.",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("Consultas DNS"),
    "docked": MessageLookupByLibrary.simpleMessage("Fija"),
    "domain": MessageLookupByLibrary.simpleMessage("Dominio"),
    "done": MessageLookupByLibrary.simpleMessage("Hecho"),
    "download": MessageLookupByLibrary.simpleMessage("Descarga"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage(
      "Ancho de banda de descarga",
    ),
    "downloadTooLarge": MessageLookupByLibrary.simpleMessage(
      "El archivo es demasiado grande para descargarlo",
    ),
    "duration": MessageLookupByLibrary.simpleMessage("Duración"),
    "edit": MessageLookupByLibrary.simpleMessage("Editar"),
    "editDashboard": MessageLookupByLibrary.simpleMessage("Editar panel"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage(
      "Editar reglas globales",
    ),
    "editProxy": MessageLookupByLibrary.simpleMessage("Editar proxy"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Editar grupo de proxies",
    ),
    "editRule": MessageLookupByLibrary.simpleMessage("Editar regla"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Editar SSID"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage(
      "Editor no disponible",
    ),
    "elapsed": MessageLookupByLibrary.simpleMessage("Tardó"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage(
      "Respaldo si está vacío",
    ),
    "emptyTip": m25,
    "en": MessageLookupByLibrary.simpleMessage("Inglés"),
    "enabled": MessageLookupByLibrary.simpleMessage("Activado"),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("Detalles del error"),
    "es": MessageLookupByLibrary.simpleMessage("Español"),
    "exclude": MessageLookupByLibrary.simpleMessage(
      "Ocultar de aplicaciones recientes",
    ),
    "excludeDstPort": MessageLookupByLibrary.simpleMessage(
      "Puertos de destino excluidos",
    ),
    "excludeDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico hacia los puertos de destino excluidos no pasa por TUN.",
    ),
    "excludeFilter": MessageLookupByLibrary.simpleMessage(
      "Filtro de exclusión",
    ),
    "excludeInterface": MessageLookupByLibrary.simpleMessage(
      "Interfaces excluidas",
    ),
    "excludeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico que llega por las interfaces excluidas, como docker0, no pasa por TUN.",
    ),
    "excludeSrcPort": MessageLookupByLibrary.simpleMessage(
      "Puertos de origen excluidos",
    ),
    "excludeSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico desde los puertos de origen excluidos no pasa por TUN.",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Excluir SSID"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "Al conectarte a una red Wi-Fi con un SSID excluido, el estado de ejecución de la app cambia automáticamente.",
    ),
    "excludeUid": MessageLookupByLibrary.simpleMessage(
      "ID de usuario excluidos",
    ),
    "excludeUidDesc": MessageLookupByLibrary.simpleMessage(
      "El tráfico de los procesos de los ID de usuario excluidos no pasa por TUN.",
    ),
    "existsTip": m26,
    "exit": MessageLookupByLibrary.simpleMessage("Salir"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage(
      "Salir de pantalla completa",
    ),
    "exitNodes": MessageLookupByLibrary.simpleMessage("Nodos de salida"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Estado esperado"),
    "expireTime": MessageLookupByLibrary.simpleMessage("Fecha de vencimiento"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Exportar archivo"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Exportar registros"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage(
      "Exportación completada",
    ),
    "extend": MessageLookupByLibrary.simpleMessage("Extensión"),
    "extendMode": MessageLookupByLibrary.simpleMessage("Modo de extensión"),
    "extendScript": MessageLookupByLibrary.simpleMessage("Script de extensión"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "Controlador externo",
    ),
    "externalControllerDesc": m27,
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage(
      "Clave del controlador externo",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("Enlace externo"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("Muy grande"),
    "fade": MessageLookupByLibrary.simpleMessage("Fundido"),
    "failedCount": m28,
    "failedItem": m29,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Filtro Fake-IP"),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage(
      "Modo de filtro Fake-IP",
    ),
    "fakeipFilterModeDesc": MessageLookupByLibrary.simpleMessage(
      "En el modo de filtro Fake-IP, la lista negra excluye las coincidencias, la lista blanca aplica Fake-IP solo a las coincidencias y rule coincide según las reglas.",
    ),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Rango Fake-IP"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage(
      "Rango Fake-IP (IPv6)",
    ),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("TTL de Fake-IP"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage(
      "Filtro de respaldo",
    ),
    "file": MessageLookupByLibrary.simpleMessage("Archivo"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "El archivo se ha modificado. ¿Guardar los cambios?",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Filtro"),
    "filters": MessageLookupByLibrary.simpleMessage("Filtros"),
    "findProcessAlways": MessageLookupByLibrary.simpleMessage("Siempre"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Buscar proceso"),
    "findProcessStrict": MessageLookupByLibrary.simpleMessage(
      "Cuando las reglas lo necesiten",
    ),
    "floating": MessageLookupByLibrary.simpleMessage("Flotante"),
    "foldAllGroups": MessageLookupByLibrary.simpleMessage(
      "Contraer todos los grupos",
    ),
    "followProfile": MessageLookupByLibrary.simpleMessage("Seguir perfil"),
    "followSystem": MessageLookupByLibrary.simpleMessage("Seguir el sistema"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Familia de fuente"),
    "fontSize": MessageLookupByLibrary.simpleMessage("Tamaño"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage("Forzar mapeo DNS"),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "Forzar mapeo DNS también analiza las conexiones cuyo dominio provino de un mapeo DNS.",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("Forzar dominios"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Los dominios forzados también se analizan; las demás conexiones que ya tienen dominio se dejan como están.",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres forzar el reinicio del núcleo?",
    ),
    "forkAuthor": MessageLookupByLibrary.simpleMessage("Autor del fork"),
    "fr": MessageLookupByLibrary.simpleMessage("Francés"),
    "fullSettingsUnlocked": MessageLookupByLibrary.simpleMessage(
      "Todos los ajustes quedan abiertos hasta reiniciar la aplicación",
    ),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m30,
    "geoUpdated": m31,
    "geodataLoader": MessageLookupByLibrary.simpleMessage(
      "Modo geo de poca memoria",
    ),
    "global": MessageLookupByLibrary.simpleMessage("Global"),
    "go": MessageLookupByLibrary.simpleMessage("Ir"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Descargar"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage(
      "Ir a la configuración de las reglas añadidas",
    ),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage(
      "Ir a la configuración del script",
    ),
    "grid": MessageLookupByLibrary.simpleMessage("Cuadrícula"),
    "groupCount": m32,
    "groupCountUnit": MessageLookupByLibrary.simpleMessage("grupos"),
    "groupTimeoutCount": m33,
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "¿Guardar los cambios en la caché?",
    ),
    "hashByInUser": MessageLookupByLibrary.simpleMessage(
      "Hash por usuario de entrada",
    ),
    "healthCheck": MessageLookupByLibrary.simpleMessage(
      "Comprobación de estado",
    ),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "El servicio auxiliar (Helper) no está disponible; no se puede activar el modo TUN. Reinstala FlClashX para restaurarlo.",
    ),
    "hex": MessageLookupByLibrary.simpleMessage("Hex"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Ocultar de la lista"),
    "hideIp": MessageLookupByLibrary.simpleMessage("Ocultar IP"),
    "hideIpDesc": MessageLookupByLibrary.simpleMessage(
      "Quita la IP de salida del panel y de la comprobación de servicios.",
    ),
    "hidePassword": MessageLookupByLibrary.simpleMessage("Ocultar contraseña"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage(
      "Ocultar proxies sin respuesta",
    ),
    "hideTimeoutProxiesDesc": MessageLookupByLibrary.simpleMessage(
      "Omite los proxies cuya última prueba de latencia superó el tiempo de espera",
    ),
    "hopInterval": MessageLookupByLibrary.simpleMessage("Intervalo de salto"),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "hostname": MessageLookupByLibrary.simpleMessage("Nombre de host"),
    "hotkeyConflictWith": m34,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "Los atajos globales funcionan incluso con la ventana oculta. Toca una acción para grabar su combinación de teclas.",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Gestión de atajos",
    ),
    "hotkeyNeedsModifier": m35,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("Sin asignar"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "No registrado; puede que otra app lo esté usando",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("horas"),
    "hoursAgo": m36,
    "hoursAgoShort": m37,
    "hue": MessageLookupByLibrary.simpleMessage("Tono"),
    "icon": MessageLookupByLibrary.simpleMessage("Icono"),
    "iconSets": MessageLookupByLibrary.simpleMessage("Conjuntos de iconos"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "Aún no hay conjuntos de iconos. Añádelos en Recursos de perfil personalizado → Conjuntos de iconos",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Estilo de icono"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("Relleno"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("Oculto"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("Simple"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("URL del icono"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignorar optimización de batería",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Importar"),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "Este archivo no es una configuración importable",
    ),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "Al importar se reemplazan los grupos de proxies, las reglas y los ajustes que tiene ahora este perfil",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage(
      "Importar desde archivo",
    ),
    "importUrl": MessageLookupByLibrary.simpleMessage("Importar desde URL"),
    "inbound": MessageLookupByLibrary.simpleMessage("Entrada"),
    "includeInterface": MessageLookupByLibrary.simpleMessage(
      "Interfaces incluidas",
    ),
    "includeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "Solo el tráfico que llega por las interfaces incluidas pasa por TUN, y las interfaces excluidas dejan de aplicarse.",
    ),
    "includeUid": MessageLookupByLibrary.simpleMessage(
      "ID de usuario incluidos",
    ),
    "includeUidDesc": MessageLookupByLibrary.simpleMessage(
      "Solo el tráfico de los procesos de los ID de usuario incluidos pasa por TUN.",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("No caduca"),
    "init": MessageLookupByLibrary.simpleMessage("Inicio"),
    "initFailed": MessageLookupByLibrary.simpleMessage("Error al iniciar"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "FlClashX encontró un error al iniciarse y no puede continuar. Copia los detalles para informar del problema. Si sigue ocurriendo, borrar los datos suele permitir que la app vuelva a iniciarse.",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("Origen de la solicitud"),
    "initiatorShort": MessageLookupByLibrary.simpleMessage("De"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "Introduce el nombre del grupo de proxies",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage(
      "Introduce el contenido de la regla",
    ),
    "installedAppsPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Se denegó el permiso de lista de apps, por lo que no se pueden mostrar las apps instaladas. Concédelo manualmente en los ajustes del sistema.",
    ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Este sistema oculta la lista de apps instaladas hasta que se concede el permiso. Autorízalo para configurar el proxy por app.",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Se requiere permiso de lista de apps",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage(
      "Fuentes instaladas",
    ),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage(
      "Selección inteligente",
    ),
    "interfaceName": MessageLookupByLibrary.simpleMessage("Nombre de interfaz"),
    "interfaceNameDesc": MessageLookupByLibrary.simpleMessage(
      "El nombre de interfaz es la interfaz de red que usan las conexiones salientes.",
    ),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage(
      "Interfaz de salida",
    ),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("Ninguna"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage(
      "Personalizada",
    ),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage(
      "Seguir configuración",
    ),
    "intranetIP": MessageLookupByLibrary.simpleMessage("IP de intranet"),
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "Introduce un rango de IP en formato CIDR, como 192.168.0.0/16",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "Una marca DSCP no puede superar 63",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage(
      "Introduce un dominio o una dirección IP",
    ),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage(
      "No es un conjunto de iconos válido",
    ),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage(
      "No es un enlace de suscripción ni un enlace para compartir proxies",
    ),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "Introduce una dirección y un puerto, como 0.0.0.0:1053",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "Solo se admite tcp o udp",
    ),
    "invalidPolicy": m38,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "Introduce un puerto o un rango como 443 u 8000-9000",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "Este código QR no contiene un enlace de perfil",
    ),
    "invalidProxy": m39,
    "invalidProxyProvider": m40,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "Introduce números o rangos como 80 u 8000-9000, separados por /",
    ),
    "invalidRuleSet": m41,
    "invalidSubRule": m42,
    "ipAddress": MessageLookupByLibrary.simpleMessage("Dirección IP"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("Historial de abusos"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("Proxy"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("Indicadores"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("Organización"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo determinar el tipo de IP",
    ),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("Buena"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("Nivel"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("Normal"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage(
      "Comprobar de nuevo",
    ),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("Arriesgada"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("Fuentes"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage(
      "IP de salida distinta",
    ),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("Sin tipo"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage(
      "Límite de solicitudes",
    ),
    "ipType": MessageLookupByLibrary.simpleMessage("Tipo"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("Empresarial"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("Centro de datos"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("Red móvil"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("Residencial"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("Versión de IP"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "El tráfico IPv6 solo se recibe mientras IPv6 esté activado.",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "Con IPv6 activado, la VPN permite el tráfico IPv6 entrante.",
    ),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage(
      "Tiempo de espera IPv6 (ms)",
    ),
    "itemsCount": m43,
    "ja": MessageLookupByLibrary.simpleMessage("Japonés"),
    "justNow": MessageLookupByLibrary.simpleMessage("Ahora mismo"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage(
      "Inactividad de keep-alive TCP",
    ),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "Intervalo de keep-alive TCP",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Clave"),
    "ko": MessageLookupByLibrary.simpleMessage("Coreano"),
    "label": MessageLookupByLibrary.simpleMessage("Etiqueta"),
    "language": MessageLookupByLibrary.simpleMessage("Idioma"),
    "large": MessageLookupByLibrary.simpleMessage("Grande"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("Última actualización"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage(
      "El inicio no se completó",
    ),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "La última vez, la app se cerró inesperadamente mientras se iniciaba. En este inicio se ha omitido la configuración automática; puedes iniciarla manualmente para reintentarlo.",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("Diseño"),
    "light": MessageLookupByLibrary.simpleMessage("Claro"),
    "lineIssueTip": m44,
    "lineWrap": MessageLookupByLibrary.simpleMessage("Ajuste de línea"),
    "link": MessageLookupByLibrary.simpleMessage("Enlace"),
    "liquidGlass": MessageLookupByLibrary.simpleMessage("Liquid Glass"),
    "liquidGlassReduced": MessageLookupByLibrary.simpleMessage(
      "Liquid Glass simplificado de forma permanente: el dispositivo no da abasto.",
    ),
    "list": MessageLookupByLibrary.simpleMessage("Lista"),
    "listen": MessageLookupByLibrary.simpleMessage("Escucha"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage(
      "Marca de enrutamiento de escucha",
    ),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "La marca de enrutamiento de escucha solo funciona en Linux.",
    ),
    "liveConnections": MessageLookupByLibrary.simpleMessage(
      "Conexiones activas",
    ),
    "loading": MessageLookupByLibrary.simpleMessage("Cargando…"),
    "local": MessageLookupByLibrary.simpleMessage("Local"),
    "localImage": MessageLookupByLibrary.simpleMessage("Imagen local"),
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "Permiso de red local denegado: con la pila gvisor, la LAN no es accesible.",
    ),
    "localProxies": MessageLookupByLibrary.simpleMessage("Proxies locales"),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Permiso de ubicación",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Se denegó el permiso de ubicación, por lo que no se puede leer el nombre de la red Wi-Fi actual. Activa el permiso de ubicación manualmente en los ajustes del sistema.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "El sistema requiere el permiso de ubicación para leer el nombre de la red Wi-Fi. En Android elige “Permitir todo el tiempo”; de lo contrario, no se podrá leer el nombre de la red Wi-Fi mientras la app esté en segundo plano.",
    ),
    "locationPermissionGuide": m45,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Se requiere permiso de ubicación",
    ),
    "logLevel": MessageLookupByLibrary.simpleMessage("Nivel de registro"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Si desactivas Logcat, se oculta la entrada de registros.",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Registros"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage(
      "Registros y diagnóstico",
    ),
    "logsTest": MessageLookupByLibrary.simpleMessage("Prueba de registros"),
    "loopback": MessageLookupByLibrary.simpleMessage(
      "Exención de loopback de UWP",
    ),
    "loose": MessageLookupByLibrary.simpleMessage("Amplio"),
    "managedByProvider": MessageLookupByLibrary.simpleMessage(
      "Gestionado por tu proveedor",
    ),
    "managedByProviderTip": MessageLookupByLibrary.simpleMessage(
      "Este valor viene de tu suscripción. Si lo cambias tú, las actualizaciones de la suscripción dejarán de tocarlo. Clic derecho o pulsación larga en la fila para devolverlo al proveedor.",
    ),
    "managedByYou": MessageLookupByLibrary.simpleMessage("Gestionado por ti"),
    "managedSettingsHint": MessageLookupByLibrary.simpleMessage(
      "Los ajustes atenuados con un candado cerrado los define tu suscripción. Toca uno para cambiarlo tú.",
    ),
    "managedSettingsOwnedHint": MessageLookupByLibrary.simpleMessage(
      "Un candado abierto marca los ajustes que has tomado; haz clic derecho o mantén pulsado uno para devolverlo al proveedor.",
    ),
    "matchCase": MessageLookupByLibrary.simpleMessage(
      "Coincidir mayúsculas y minúsculas",
    ),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage(
      "Coincidir con IP de origen",
    ),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("Máximo de fallos"),
    "maxLengthTip": m46,
    "maximize": MessageLookupByLibrary.simpleMessage("Maximizar"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage(
      "Memoria residente",
    ),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("App y compartida"),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("Heap inactivo"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("Heap en uso"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage(
      "El núcleo no se está ejecutando",
    ),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage(
      "Sobrecarga del runtime",
    ),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage(
      "Pilas de goroutines",
    ),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "Estimado a partir de la memoria residente del proceso; puede diferir de lo que indica el sistema.",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "El núcleo se ejecuta dentro del proceso de la app. Su parte se estima a partir de las estadísticas del runtime, y el resto cuenta como memoria de la app y compartida.",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage(
      "Información de memoria",
    ),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage(
      "Memoria que usan la app y el núcleo",
    ),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("Memoria liberada"),
    "memoryReleasedSize": m47,
    "menuBarMode": MessageLookupByLibrary.simpleMessage(
      "Fijar en la barra de menús",
    ),
    "menuBarModeDesc": MessageLookupByLibrary.simpleMessage(
      "La app vive en la barra de menús: la ventana se abre como un panel desde su icono y no hay icono en el Dock. El botón de zoom también la fija.",
    ),
    "messageTest": MessageLookupByLibrary.simpleMessage("Prueba de mensaje"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage(
      "Esto es un mensaje.",
    ),
    "minimize": MessageLookupByLibrary.simpleMessage("Minimizar"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage(
      "Minimizar al salir",
    ),
    "minutes": MessageLookupByLibrary.simpleMessage("minutos"),
    "minutesAgo": m48,
    "minutesAgoShort": m49,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Puerto mixto"),
    "mode": MessageLookupByLibrary.simpleMessage("Modo"),
    "monochromeIcon": MessageLookupByLibrary.simpleMessage("Icono monocromo"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Monocromo"),
    "monthsAgo": m50,
    "monthsAgoShort": m51,
    "more": MessageLookupByLibrary.simpleMessage("Más"),
    "name": MessageLookupByLibrary.simpleMessage("Nombre"),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage(
      "Barra inferior",
    ),
    "network": MessageLookupByLibrary.simpleMessage("Red"),
    "networkAccessDeniedError": m52,
    "networkBadResponseError": m53,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage(
      "Se canceló la solicitud",
    ),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "No se pudo conectar con el servidor. Comprueba tu conexión de red o los ajustes del proxy",
    ),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "No se pudo resolver la dirección del servidor. Comprueba que la URL sea correcta y que el DNS funcione",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("Nombre de la red"),
    "networkNotFoundError": m54,
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "Demasiadas solicitudes (HTTP 429). Espera un momento e inténtalo de nuevo",
    ),
    "networkRequestFailed": m55,
    "networkSecret": MessageLookupByLibrary.simpleMessage("Clave de la red"),
    "networkServerError": m56,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Velocidad de red"),
    "networkTakeover": MessageLookupByLibrary.simpleMessage(
      "Control del tráfico",
    ),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "Se agotó el tiempo de espera de la solicitud. Comprueba tu red o el proxy e inténtalo de nuevo",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "Falló la conexión segura. Puede que el certificado del servidor no sea válido o que la conexión esté siendo interceptada",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("Tipo de red"),
    "newProxyChain": MessageLookupByLibrary.simpleMessage("Nueva cadena"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("Coincidencia siguiente"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noData": MessageLookupByLibrary.simpleMessage("Sin datos"),
    "noInfo": MessageLookupByLibrary.simpleMessage("Sin información"),
    "noLogsToday": MessageLookupByLibrary.simpleMessage(
      "No hay registros de hoy",
    ),
    "noNetwork": MessageLookupByLibrary.simpleMessage("Sin red"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("Apps sin red"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage(
      "No resolver nombre de host",
    ),
    "noSearchResults": MessageLookupByLibrary.simpleMessage(
      "No hay resultados",
    ),
    "nodes": MessageLookupByLibrary.simpleMessage("Nodos"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage(
      "Este recurso externo no es un archivo de texto",
    ),
    "none": MessageLookupByLibrary.simpleMessage("Ninguno"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "No se puede seleccionar el grupo de proxies actual",
    ),
    "ntpInterval": MessageLookupByLibrary.simpleMessage(
      "Intervalo de sincronización (minutos)",
    ),
    "ntpStatusDesc": MessageLookupByLibrary.simpleMessage(
      "NTP obtiene la hora de un servidor NTP en lugar del reloj del sistema.",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Añade un perfil para empezar",
    ),
    "nullTip": m57,
    "numberRangeTip": m58,
    "numberTip": m59,
    "obfs": MessageLookupByLibrary.simpleMessage("Ofuscación"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("Host de ofuscación"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("Modo de ofuscación"),
    "obfsParam": MessageLookupByLibrary.simpleMessage(
      "Parámetro de ofuscación",
    ),
    "obfsPassword": MessageLookupByLibrary.simpleMessage(
      "Contraseña de ofuscación",
    ),
    "onDemand": MessageLookupByLibrary.simpleMessage("Bajo demanda"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Bajo demanda pausa el proxy en las redes Wi-Fi excluidas.",
    ),
    "oneline": MessageLookupByLibrary.simpleMessage("Una línea"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Contar solo el tráfico del proxy",
    ),
    "openLogsFolder": MessageLookupByLibrary.simpleMessage(
      "Abrir carpeta de registros",
    ),
    "openVpnSettings": MessageLookupByLibrary.simpleMessage(
      "Abrir ajustes de VPN",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("Opcional"),
    "options": MessageLookupByLibrary.simpleMessage("Opciones"),
    "originalRepository": MessageLookupByLibrary.simpleMessage(
      "Repositorio original",
    ),
    "other": MessageLookupByLibrary.simpleMessage("Otros"),
    "outbound": MessageLookupByLibrary.simpleMessage("Salida"),
    "outboundExit": MessageLookupByLibrary.simpleMessage("Salida"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("IP de salida"),
    "outboundLocation": MessageLookupByLibrary.simpleMessage(
      "Ubicación de salida",
    ),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Modo de salida"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage(
      "Sobrescribir destino",
    ),
    "overrideDestinationDesc": MessageLookupByLibrary.simpleMessage(
      "Sobrescribir destino se conecta al dominio detectado en lugar de a la dirección original.",
    ),
    "overrideEntries": MessageLookupByLibrary.simpleMessage(
      "Entradas de sobrescritura",
    ),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("Analizar IP pura"),
    "parsePureIpDesc": MessageLookupByLibrary.simpleMessage(
      "Analizar IP pura analiza las conexiones que solo llevan una dirección IP.",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Contraseña"),
    "paste": MessageLookupByLibrary.simpleMessage("Pegar"),
    "peers": MessageLookupByLibrary.simpleMessage("Pares"),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("Elegir del álbum"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("Fijar ventana"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Introduce un nombre para el script",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Sube un código QR válido",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("Complemento"),
    "pluginCipher": MessageLookupByLibrary.simpleMessage(
      "Cifrado del complemento",
    ),
    "pluginHost": MessageLookupByLibrary.simpleMessage("Host del complemento"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("Modo del complemento"),
    "pluginPassword": MessageLookupByLibrary.simpleMessage(
      "Contraseña del complemento",
    ),
    "pluginPath": MessageLookupByLibrary.simpleMessage("Ruta del complemento"),
    "pluginUsername": MessageLookupByLibrary.simpleMessage(
      "Usuario del complemento",
    ),
    "port": MessageLookupByLibrary.simpleMessage("Puerto"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Introduce un puerto diferente",
    ),
    "portHopping": MessageLookupByLibrary.simpleMessage("Salto de puertos"),
    "portTip": m60,
    "portValue": m61,
    "ports": MessageLookupByLibrary.simpleMessage("Puertos"),
    "preChannelTip": MessageLookupByLibrary.simpleMessage("Esta versión preliminar es una aplicación aparte. Vuelve a añadir tus suscripciones por enlace o importa archivos de perfil individuales."),
    "preChannelTipTitle": MessageLookupByLibrary.simpleMessage("FlClashX Pre"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("Clave precompartida"),
    "preferred": MessageLookupByLibrary.simpleMessage("Preferido"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Requisitos previos"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage(
      "Pulsa una combinación de teclas",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Vista previa"),
    "previousMatch": MessageLookupByLibrary.simpleMessage(
      "Coincidencia anterior",
    ),
    "privateKey": MessageLookupByLibrary.simpleMessage("Clave privada"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage(
      "Frase de contraseña de la clave privada",
    ),
    "process": MessageLookupByLibrary.simpleMessage("Proceso"),
    "profile": MessageLookupByLibrary.simpleMessage("Perfil"),
    "profileAddedTip": m62,
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("Introduce un intervalo válido"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Introduce el intervalo de actualización automática",
        ),
    "profileDaysFigure": m63,
    "profileDetails": MessageLookupByLibrary.simpleMessage("Detalles"),
    "profileExpired": MessageLookupByLibrary.simpleMessage("Vencida"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "El perfil se ha modificado. ¿Desactivar la actualización automática?",
    ),
    "profileHoursFigure": m64,
    "profileLeftOfTotal": m65,
    "profileMinutesFigure": m66,
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Introduce el nombre del perfil",
    ),
    "profileNoExpiry": MessageLookupByLibrary.simpleMessage("Sin vencimiento"),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Se aplica solo a este perfil; lo que no añadas usa su valor predeterminado.",
    ),
    "profileTrafficUnlimited": MessageLookupByLibrary.simpleMessage(
      "Ilimitado",
    ),
    "profileTunSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Se aplica solo a este perfil y tiene prioridad sobre las entradas de sobrescritura de TUN de los ajustes de red.",
    ),
    "profileTypeCustom": MessageLookupByLibrary.simpleMessage("Personalizado"),
    "profileTypeFile": MessageLookupByLibrary.simpleMessage("Archivo"),
    "profileTypeSubscription": MessageLookupByLibrary.simpleMessage(
      "Suscripción",
    ),
    "profileUntil": m67,
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Introduce una URL de perfil válida",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Introduce la URL del perfil",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Perfiles"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Ordenar perfiles"),
    "project": MessageLookupByLibrary.simpleMessage("Proyecto"),
    "protocol": MessageLookupByLibrary.simpleMessage("Protocolo"),
    "protocolParam": MessageLookupByLibrary.simpleMessage(
      "Parámetro del protocolo",
    ),
    "protocolVersion": MessageLookupByLibrary.simpleMessage(
      "Versión del protocolo",
    ),
    "providerInUse": m68,
    "providerReplacedTip": MessageLookupByLibrary.simpleMessage(
      "Este proveedor se reemplazó mientras lo editabas. Vuelve a abrirlo para editar el actual.",
    ),
    "providerUrlTip": MessageLookupByLibrary.simpleMessage(
      "Solo se admiten proveedores remotos",
    ),
    "providers": MessageLookupByLibrary.simpleMessage("Recursos externos"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesCount": m69,
    "proxiesProfileLabel": m70,
    "proxiesRemovedTip": m71,
    "proxiesReplacedTip": m72,
    "proxyChain": MessageLookupByLibrary.simpleMessage("Cadena"),
    "proxyChainDevice": MessageLookupByLibrary.simpleMessage("Dispositivo"),
    "proxyChainEntry": MessageLookupByLibrary.simpleMessage("Entrada"),
    "proxyChainExit": MessageLookupByLibrary.simpleMessage("Salida"),
    "proxyChainHopsDesc": MessageLookupByLibrary.simpleMessage(
      "El dispositivo se conecta a la entrada y el tráfico sale a internet por la salida.",
    ),
    "proxyChainIncomplete": MessageLookupByLibrary.simpleMessage(
      "Pon un nombre a la cadena y elige todos los saltos",
    ),
    "proxyChainInternet": MessageLookupByLibrary.simpleMessage("Internet"),
    "proxyChainIsMatchTarget": m73,
    "proxyChainIsRuleTarget": m74,
    "proxyChainMiddle": MessageLookupByLibrary.simpleMessage("Intermedio"),
    "proxyChainMissingHop": m75,
    "proxyChainNameTaken": m76,
    "proxyChainProviderHop": m77,
    "proxyChainRepeatedHop": MessageLookupByLibrary.simpleMessage(
      "El mismo salto está elegido dos veces",
    ),
    "proxyChainUnchainableHop": m78,
    "proxyChainUnreadableFilter": m79,
    "proxyChains": MessageLookupByLibrary.simpleMessage("Cadena de proxies"),
    "proxyChainsDesc": MessageLookupByLibrary.simpleMessage("El tráfico pasa por los saltos en orden y los sitios solo ven la salida. Las cadenas se guardan en este dispositivo."),
    "proxyChainsTitle": MessageLookupByLibrary.simpleMessage(
      "Cadenas de proxies",
    ),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Grupo de proxies"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "El grupo de proxies está vacío",
    ),
    "proxyGroupInUse": m80,
    "proxyGroupsAfterStart": MessageLookupByLibrary.simpleMessage(
      "Los grupos aparecen aquí cuando se inicia el núcleo",
    ),
    "proxyGroupsCount": m81,
    "proxyProviders": MessageLookupByLibrary.simpleMessage(
      "Proveedores de proxies",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("Tipo de proxy"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Depurar caché"),
    "publicKey": MessageLookupByLibrary.simpleMessage("Clave pública"),
    "pullToTestDelay": MessageLookupByLibrary.simpleMessage(
      "Desliza hacia abajo para medir la latencia",
    ),
    "pullToUpdateSubscription": MessageLookupByLibrary.simpleMessage(
      "Desliza hacia abajo para actualizar la suscripción",
    ),
    "pureBlack": MessageLookupByLibrary.simpleMessage("Negro puro"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Modo negro puro"),
    "qrcode": MessageLookupByLibrary.simpleMessage("Código QR"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Escanea un código QR para obtener un perfil",
    ),
    "qrcodeTooLongTip": MessageLookupByLibrary.simpleMessage(
      "Este enlace es demasiado largo para un código QR. Usa Copiar enlace.",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("Acciones rápidas"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("Edición rápida"),
    "recentRequests": MessageLookupByLibrary.simpleMessage(
      "Solicitudes recientes",
    ),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("Sugeridos"),
    "recordType": MessageLookupByLibrary.simpleMessage("Tipo de registro"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Puerto Redir"),
    "redo": MessageLookupByLibrary.simpleMessage("Rehacer"),
    "regex": MessageLookupByLibrary.simpleMessage("Expresión regular"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("Liberar memoria"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo liberar la memoria",
    ),
    "releaseToTestDelay": MessageLookupByLibrary.simpleMessage(
      "Suelta para medir la latencia",
    ),
    "releaseToUpdateSubscription": MessageLookupByLibrary.simpleMessage(
      "Suelta para actualizar la suscripción",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("Remoto"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("Destino remoto"),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage(
      "Resolución DNS remota",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Quitar"),
    "rename": MessageLookupByLibrary.simpleMessage("Renombrar"),
    "renew": MessageLookupByLibrary.simpleMessage("Renovar"),
    "replace": MessageLookupByLibrary.simpleMessage("Reemplazar"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("Reemplazar todo"),
    "request": MessageLookupByLibrary.simpleMessage("Solicitud"),
    "requestHeaders": MessageLookupByLibrary.simpleMessage(
      "Encabezados de solicitud",
    ),
    "requests": MessageLookupByLibrary.simpleMessage("Solicitudes"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage(
      "Solicitudes y actualizaciones",
    ),
    "required": MessageLookupByLibrary.simpleMessage("Obligatorio"),
    "reset": MessageLookupByLibrary.simpleMessage("Restablecer"),
    "resetApp": MessageLookupByLibrary.simpleMessage(
      "Restablecer la aplicación",
    ),
    "resetAppTip": MessageLookupByLibrary.simpleMessage(
      "Se eliminarán todos los perfiles, los ajustes y la carpeta de trabajo de la aplicación, y después la aplicación se cerrará. ¿Continuar?",
    ),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "Esta página tiene cambios. ¿Seguro que quieres restablecer?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres restablecer?",
    ),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Intervalo de actualización automática",
    ),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "El intervalo de actualización automática debe ser mayor que 0",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("Recursos"),
    "respectRules": MessageLookupByLibrary.simpleMessage("Respetar reglas"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "Respetar reglas enruta las conexiones DNS según las reglas y requiere un Proxy Server Nameserver.",
    ),
    "responseCode": MessageLookupByLibrary.simpleMessage("Código de respuesta"),
    "restart": MessageLookupByLibrary.simpleMessage("Reiniciar"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "¿Seguro que quieres reiniciar el núcleo?",
    ),
    "result": MessageLookupByLibrary.simpleMessage("Resultado"),
    "retry": MessageLookupByLibrary.simpleMessage("Reintentar"),
    "returnAllToProvider": MessageLookupByLibrary.simpleMessage(
      "Devolver los ajustes al proveedor",
    ),
    "returnAllToProviderTip": MessageLookupByLibrary.simpleMessage(
      "Todos los ajustes que cambiaste tú volverán a seguir la suscripción.",
    ),
    "returnToProvider": MessageLookupByLibrary.simpleMessage(
      "Devolver al proveedor",
    ),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Direcciones de ruta"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage(
      "Direcciones excluidas de la ruta",
    ),
    "routingMark": MessageLookupByLibrary.simpleMessage(
      "Marca de enrutamiento",
    ),
    "ru": MessageLookupByLibrary.simpleMessage("Ruso"),
    "rule": MessageLookupByLibrary.simpleMessage("Regla"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage(
      "Regla lógica AND",
    ),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el dominio completo",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una palabra clave del dominio",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una expresión regular de dominio",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un sufijo de dominio",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Coincidencia con comodines; solo se admiten * y ?",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con la marca DSCP (solo entrada UDP de tproxy)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el rango de puertos de destino",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el código de país de la IP",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con los dominios de Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre de la entrada",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el puerto de entrada",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el tipo de entrada",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre de usuario de entrada; separa varios usuarios con /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el ASN de la IP",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de direcciones IP; IP-CIDR6 es solo un alias",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de direcciones IP",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de sufijo de IP",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con todas las solicitudes, sin necesidad de condiciones",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con TCP o UDP",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage(
      "Regla lógica NOT",
    ),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("Regla lógica OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre del proceso; en Android coincide con el nombre del paquete",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una expresión regular del nombre del proceso; en Android coincide con el nombre del paquete",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con comodines en el nombre del proceso; solo se admiten * y ?",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con la ruta completa del proceso",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una expresión regular de la ruta del proceso",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con comodines en la ruta del proceso; solo se admiten * y ?",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el nombre de rematch; separa varios nombres con /",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Hace referencia a un conjunto de reglas; requiere rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el código de país de la IP de origen",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el ASN de la IP de origen",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de direcciones IP de origen",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con un rango de sufijo de IP de origen",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el rango de puertos de origen",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con una subregla; cuidado con los paréntesis",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Coincide con el ID de usuario de Linux",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("La regla está vacía"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "Las reglas deben ser una lista YAML con una regla por elemento, por ejemplo - DOMAIN,example.com,DIRECT",
    ),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BitTorrent directo",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "Bloquear DNS sobre TLS",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage(
      "Bloquear bucle del proxy",
    ),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage(
      "Bloquear QUIC",
    ),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage(
      "Bloquear STUN",
    ),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("LAN directa"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple y Microsoft directos",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage(
      "Proveedores de reglas",
    ),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Conjunto de reglas"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage(
      "El conjunto de reglas no tiene entradas utilizables",
    ),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage(
      "No se puede leer este archivo mrs",
    ),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "El conjunto de reglas mezcla dominios y rangos de IP, por lo que no se puede determinar su tipo",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Destino de la regla"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "La regla debe empezar con un tipo admitido, por ejemplo DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("Reglas"),
    "rulesCount": m82,
    "runtimeConfig": MessageLookupByLibrary.simpleMessage(
      "Configuración de ejecución",
    ),
    "safeModeAppTitle": m83,
    "saturation": MessageLookupByLibrary.simpleMessage("Saturación"),
    "save": MessageLookupByLibrary.simpleMessage("Guardar"),
    "saveChanges": MessageLookupByLibrary.simpleMessage(
      "¿Guardar los cambios?",
    ),
    "script": MessageLookupByLibrary.simpleMessage("Script"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Modo script: reescribe todo el perfil con un script de extensión",
    ),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage(
      "Ir a la selección",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Buscar"),
    "seconds": MessageLookupByLibrary.simpleMessage("segundos"),
    "secondsCount": m84,
    "secretKey": MessageLookupByLibrary.simpleMessage("Clave"),
    "sectionsInEffect": m85,
    "select": MessageLookupByLibrary.simpleMessage("Seleccionar"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Seleccionar todo"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage(
      "Selecciona un conjunto de reglas",
    ),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Selecciona una estrategia de división",
    ),
    "send": MessageLookupByLibrary.simpleMessage("Enviar"),
    "sendDeviceHeaders": MessageLookupByLibrary.simpleMessage("Enviar HWID"),
    "sendFromPhone": MessageLookupByLibrary.simpleMessage(
      "Enviar desde el teléfono",
    ),
    "sendFromPhoneConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "¿Importar el enlace enviado desde el teléfono?",
    ),
    "sendFromPhoneNoNetwork": MessageLookupByLibrary.simpleMessage(
      "Este dispositivo no está conectado a una red local",
    ),
    "sendFromPhonePageHint": MessageLookupByLibrary.simpleMessage(
      "Enlace de suscripción o enlace para compartir un proxy",
    ),
    "sendFromPhonePageSent": MessageLookupByLibrary.simpleMessage(
      "Enviado. Confirma la importación en el otro dispositivo.",
    ),
    "sendFromPhonePageTitle": MessageLookupByLibrary.simpleMessage(
      "Enviar un enlace a FlClashX",
    ),
    "sendFromPhonePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Para recibir un enlace desde el teléfono, FlClashX necesita el permiso Dispositivos cercanos, que le da acceso a la red local. Actívalo en los ajustes de la aplicación.",
    ),
    "sendFromPhoneTip": MessageLookupByLibrary.simpleMessage(
      "Escanea el código con la cámara del teléfono y pega el enlace en la página que se abre. Ambos dispositivos deben estar en la misma red. Si la página no se abre en Android 17 o posterior, concede al navegador del teléfono el permiso Dispositivos cercanos.",
    ),
    "server": MessageLookupByLibrary.simpleMessage("Servidor"),
    "serviceAbnormalCount": m86,
    "serviceAllAvailable": MessageLookupByLibrary.simpleMessage(
      "Todo disponible",
    ),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("Disponible"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("Bloqueado"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("Comprobar todo"),
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("Próximamente"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage(
      "ISP no permitido",
    ),
    "serviceFailed": MessageLookupByLibrary.simpleMessage(
      "Error en la comprobación",
    ),
    "serviceManage": MessageLookupByLibrary.simpleMessage(
      "Gestionar servicios",
    ),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage(
      "Solo originales",
    ),
    "servicePending": MessageLookupByLibrary.simpleMessage("Sin comprobar"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage(
      "Acceso restringido",
    ),
    "serviceShownOnDashboard": MessageLookupByLibrary.simpleMessage(
      "Se muestra en el panel",
    ),
    "serviceStatus": MessageLookupByLibrary.simpleMessage(
      "Estado del servicio",
    ),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("No disponible"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage(
      "Región no compatible",
    ),
    "settingEntries": MessageLookupByLibrary.simpleMessage("ajustes"),
    "settings": MessageLookupByLibrary.simpleMessage("Ajustes"),
    "settingsCount": m87,
    "shareLinkUnreadable": m88,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage(
      "No se pudo leer ningún proxy de los enlaces",
    ),
    "shareLogs": MessageLookupByLibrary.simpleMessage("Compartir registros"),
    "shareQrcodeTip": MessageLookupByLibrary.simpleMessage(
      "Escanea con FlClashX en otro dispositivo para importar este perfil.",
    ),
    "show": MessageLookupByLibrary.simpleMessage("Mostrar"),
    "showLess": MessageLookupByLibrary.simpleMessage("Contraer"),
    "showMore": MessageLookupByLibrary.simpleMessage("Expandir"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "Botón de detener en la notificación",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("Mostrar contraseña"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Inicio silencioso"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "El inicio silencioso arranca sin mostrar la ventana.",
    ),
    "singleAdd": MessageLookupByLibrary.simpleMessage("Añadir uno"),
    "singleImport": MessageLookupByLibrary.simpleMessage("Importar uno"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "Introduce aquí un solo enlace; para varios, usa la edición rápida de la lista",
    ),
    "singleValueTip": m89,
    "size": MessageLookupByLibrary.simpleMessage("Tamaño"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage(
      "Omitir verificación de certificado",
    ),
    "skipDomain": MessageLookupByLibrary.simpleMessage("Omitir dominios"),
    "skipDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Un dominio detectado que esté en la lista de dominios omitidos no se usa.",
    ),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage(
      "Omitir direcciones de destino",
    ),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage(
      "Omitir direcciones de origen",
    ),
    "slide": MessageLookupByLibrary.simpleMessage("Deslizar"),
    "sliders": MessageLookupByLibrary.simpleMessage("Reguladores"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("Protocolos"),
    "sniffer": MessageLookupByLibrary.simpleMessage("Sniffer"),
    "snifferStatusDesc": MessageLookupByLibrary.simpleMessage(
      "El sniffer lee el dominio del tráfico TLS, HTTP y QUIC para que las reglas puedan aplicarse.",
    ),
    "socksPort": MessageLookupByLibrary.simpleMessage("Puerto SOCKS"),
    "softStyle": MessageLookupByLibrary.simpleMessage("Suave"),
    "sort": MessageLookupByLibrary.simpleMessage("Ordenar"),
    "source": MessageLookupByLibrary.simpleMessage("Origen"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Proxy especial"),
    "specialRules": MessageLookupByLibrary.simpleMessage("Reglas especiales"),
    "spectrum": MessageLookupByLibrary.simpleMessage("Espectro"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage(
      "Estadísticas de velocidad",
    ),
    "splitStrategy": MessageLookupByLibrary.simpleMessage(
      "Estrategia de división",
    ),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "La estrategia de división no puede estar vacía",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("No hay SSID"),
    "stableImportRetry": MessageLookupByLibrary.simpleMessage("Reintentar"),
    "stableImportSkip": MessageLookupByLibrary.simpleMessage(
      "Continuar sin ellos",
    ),
    "stableImportTip": MessageLookupByLibrary.simpleMessage(
      "FlClashX Pre aún no pudo tomar los perfiles y ajustes de FlClashX. Si FlClashX está abierto, ciérralo y vuelve a intentarlo.",
    ),
    "stableImportTitle": MessageLookupByLibrary.simpleMessage(
      "Traer tus perfiles de FlClashX",
    ),
    "stackMode": MessageLookupByLibrary.simpleMessage("Modo de pila"),
    "stackTrace": MessageLookupByLibrary.simpleMessage("Seguimiento de pila"),
    "standard": MessageLookupByLibrary.simpleMessage("Estándar"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Modo estándar: añade reglas sobre el perfil",
    ),
    "start": MessageLookupByLibrary.simpleMessage("Iniciar"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage(
      "Empezar desde cero",
    ),
    "startVpn": MessageLookupByLibrary.simpleMessage("Iniciando VPN…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage(
      "Inicio y segundo plano",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Estado"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "Con DNS desactivado, se usa el DNS del sistema.",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Detener"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Deteniendo VPN…"),
    "strategy": MessageLookupByLibrary.simpleMessage("Estrategia"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("Ruta estricta"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "La ruta estricta evita que el tráfico, como el DNS, eluda TUN y, con IPv6 desactivado, bloquea las conexiones IPv6 de este dispositivo.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Estilo"),
    "submit": MessageLookupByLibrary.simpleMessage("Enviar"),
    "subscriptionExpired": MessageLookupByLibrary.simpleMessage(
      "Tu suscripción ha caducado",
    ),
    "subscriptionExpiresInDays": m90,
    "subscriptionExpiresSoon": MessageLookupByLibrary.simpleMessage(
      "La suscripción caduca pronto",
    ),
    "subscriptionExpiresToday": MessageLookupByLibrary.simpleMessage(
      "Tu suscripción caduca hoy",
    ),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage(
      "Información de la suscripción",
    ),
    "subscriptionUpdated": MessageLookupByLibrary.simpleMessage(
      "Suscripción actualizada",
    ),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Introduce tu contraseña para sudo",
    ),
    "support": MessageLookupByLibrary.simpleMessage("Soporte"),
    "suspended": MessageLookupByLibrary.simpleMessage("Suspendido…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("Cambiar de perfil"),
    "sync": MessageLookupByLibrary.simpleMessage("Sincronizar"),
    "system": MessageLookupByLibrary.simpleMessage("Sistema"),
    "systemApp": MessageLookupByLibrary.simpleMessage("Apps del sistema"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("Proxy del sistema"),
    "tab": MessageLookupByLibrary.simpleMessage("Pestaña"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage(
      "Animación de pestañas",
    ),
    "takeOver": MessageLookupByLibrary.simpleMessage("Cambiar"),
    "tapIconToRetry": MessageLookupByLibrary.simpleMessage(
      "Toca el icono para reintentar",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage(
      "Toca para autorizar",
    ),
    "target": MessageLookupByLibrary.simpleMessage("Destino"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP concurrente"),
    "testInterval": MessageLookupByLibrary.simpleMessage("Intervalo de prueba"),
    "testUrl": MessageLookupByLibrary.simpleMessage("URL de prueba"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("Probar al usarse"),
    "textScale": MessageLookupByLibrary.simpleMessage("Escala del texto"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage(
      "Así se verá el texto en la app",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("Tema"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Color del tema"),
    "themeMode": MessageLookupByLibrary.simpleMessage("Apariencia"),
    "tight": MessageLookupByLibrary.simpleMessage("Ajustado"),
    "time": MessageLookupByLibrary.simpleMessage("Hora"),
    "timeout": MessageLookupByLibrary.simpleMessage("Tiempo agotado"),
    "tintedStyle": MessageLookupByLibrary.simpleMessage("Tintado"),
    "tip": MessageLookupByLibrary.simpleMessage("Consejo"),
    "toggle": MessageLookupByLibrary.simpleMessage("Alternar"),
    "tolerance": MessageLookupByLibrary.simpleMessage("Tolerancia"),
    "tools": MessageLookupByLibrary.simpleMessage("Ajustes"),
    "torch": MessageLookupByLibrary.simpleMessage("Linterna"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalDownload": MessageLookupByLibrary.simpleMessage("Descargado"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("Tráfico total"),
    "totalUpload": MessageLookupByLibrary.simpleMessage("Subido"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Puerto TProxy"),
    "traffic": MessageLookupByLibrary.simpleMessage("Tráfico"),
    "trafficPeak": m91,
    "trafficTotal": m92,
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Uso de tráfico"),
    "transport": MessageLookupByLibrary.simpleMessage("Transporte"),
    "transportHeaders": m93,
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo autorizar TUN, por lo que se desactivó.",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "TUN solo funciona en modo administrador.",
    ),
    "tunOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Las entradas añadidas aquí sustituyen los ajustes de TUN de todos los perfiles; lo que no añadas conserva el ajuste del propio perfil. Las entradas que añade un perfil personalizado tienen prioridad.",
    ),
    "tunStartFailed": MessageLookupByLibrary.simpleMessage(
      "No se pudo iniciar TUN, por lo que se desactivó.",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Desactivar"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Activar"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage(
      "Modo de retransmisión UDP",
    ),
    "udpTimeout": MessageLookupByLibrary.simpleMessage("Tiempo de espera UDP"),
    "udpTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "El tiempo de espera UDP se indica en segundos y solo funciona con las pilas gvisor, system y mixed.",
    ),
    "ultra": MessageLookupByLibrary.simpleMessage("Ultra"),
    "undo": MessageLookupByLibrary.simpleMessage("Deshacer"),
    "unfoldAllGroups": MessageLookupByLibrary.simpleMessage(
      "Expandir todos los grupos",
    ),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Latencia unificada"),
    "unknown": MessageLookupByLibrary.simpleMessage("Desconocido"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Error de red desconocido",
    ),
    "unmaximize": MessageLookupByLibrary.simpleMessage("Restaurar tamaño"),
    "unnamed": MessageLookupByLibrary.simpleMessage("Sin nombre"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("Desfijar ventana"),
    "update": MessageLookupByLibrary.simpleMessage("Actualizar"),
    "updateErrorBusy": MessageLookupByLibrary.simpleMessage(
      "Espera a que la conexión termine de iniciarse o detenerse.",
    ),
    "updateErrorChecksum": MessageLookupByLibrary.simpleMessage(
      "La descarga no coincide con la suma de comprobación de la versión y se eliminó.",
    ),
    "updateErrorIdentity": MessageLookupByLibrary.simpleMessage(
      "La descarga no está firmada como esta app y se eliminó.",
    ),
    "updateErrorIncomplete": MessageLookupByLibrary.simpleMessage(
      "La descarga terminó antes de tiempo.",
    ),
    "updateErrorInstall": MessageLookupByLibrary.simpleMessage(
      "No se pudo instalar la actualización.",
    ),
    "updateErrorNetwork": MessageLookupByLibrary.simpleMessage(
      "La descarga falló. Comprueba la conexión e inténtalo de nuevo.",
    ),
    "updateErrorNoAsset": MessageLookupByLibrary.simpleMessage(
      "Esta versión no tiene compilación para este dispositivo.",
    ),
    "updateErrorNoChecksum": MessageLookupByLibrary.simpleMessage(
      "Esta versión no publica suma de comprobación, así que la descarga no se puede verificar.",
    ),
    "updateErrorNotNewer": MessageLookupByLibrary.simpleMessage(
      "La descarga no es más reciente que esta app.",
    ),
    "updateErrorPermission": MessageLookupByLibrary.simpleMessage(
      "Permite instalar apps de este origen y vuelve a tocar Instalar.",
    ),
    "updateErrorSafeMode": MessageLookupByLibrary.simpleMessage(
      "El modo seguro no instala actualizaciones.",
    ),
    "updateErrorTooLarge": MessageLookupByLibrary.simpleMessage(
      "La descarga es más grande de lo que indica la versión.",
    ),
    "updateErrorUntrustedHost": MessageLookupByLibrary.simpleMessage(
      "La descarga se redirigió a una dirección que no es GitHub.",
    ),
    "updateExiting": MessageLookupByLibrary.simpleMessage(
      "Cerrando para terminar la actualización…",
    ),
    "updateHandedOff": MessageLookupByLibrary.simpleMessage(
      "Termina la actualización en el instalador que se abrió.",
    ),
    "updateHide": MessageLookupByLibrary.simpleMessage("Ocultar"),
    "updateInstall": MessageLookupByLibrary.simpleMessage("Instalar"),
    "updateInstalling": MessageLookupByLibrary.simpleMessage(
      "Iniciando el instalador…",
    ),
    "updateOpenedImage": MessageLookupByLibrary.simpleMessage(
      "Esta copia no se puede reemplazar en su sitio. Arrastra la app desde la imagen de disco abierta a Aplicaciones.",
    ),
    "updatePackageManager": MessageLookupByLibrary.simpleMessage(
      "Esta copia la gestiona tu gestor de paquetes. Actualízala desde allí.",
    ),
    "updateReady": MessageLookupByLibrary.simpleMessage(
      "Descargada y verificada.",
    ),
    "updateUnsupported": MessageLookupByLibrary.simpleMessage(
      "Esta copia no puede actualizarse sola. Descarga la nueva versión en GitHub.",
    ),
    "updateVerifying": MessageLookupByLibrary.simpleMessage(
      "Comprobando la descarga…",
    ),
    "updateViewOnGitHub": MessageLookupByLibrary.simpleMessage("Ver en GitHub"),
    "updatingSubscription": MessageLookupByLibrary.simpleMessage(
      "Actualizando la suscripción…",
    ),
    "upload": MessageLookupByLibrary.simpleMessage("Subida"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage(
      "Ancho de banda de subida",
    ),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlTip": m94,
    "useHosts": MessageLookupByLibrary.simpleMessage("Usar hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage(
      "Usar hosts del sistema",
    ),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("Tráfico usado"),
    "username": MessageLookupByLibrary.simpleMessage("Usuario"),
    "value": MessageLookupByLibrary.simpleMessage("Valor"),
    "vibration": MessageLookupByLibrary.simpleMessage("Vibración"),
    "vibrationDesc": MessageLookupByLibrary.simpleMessage(
      "Respuesta táctil, vibración al mantener pulsado y al abrir la app.",
    ),
    "view": MessageLookupByLibrary.simpleMessage("Ver"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("IPv4 virtual"),
    "vividStyle": MessageLookupByLibrary.simpleMessage("Vivo"),
    "vpnBlockedByAnotherApp": MessageLookupByLibrary.simpleMessage(
      "Otra app bloquea la VPN",
    ),
    "vpnBlockedByAnotherAppTip": MessageLookupByLibrary.simpleMessage(
      "Otra app de VPN tiene activada la «VPN siempre activa». Desactívala para esa app en los ajustes de VPN y vuelve a iniciar.",
    ),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "Se detectó un cambio en la configuración relacionada con la VPN",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "La VPN enruta automáticamente todo el tráfico del sistema a través de VpnService.",
    ),
    "vpnPermissionNotGranted": m95,
    "vpnRestrictedByAdministrator": MessageLookupByLibrary.simpleMessage(
      "El administrador de este dispositivo restringe la VPN",
    ),
    "website": MessageLookupByLibrary.simpleMessage("Sitio web"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("Modo lista blanca"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage(
      "Escribir en el sistema",
    ),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "Escribir en el sistema también ajusta el reloj del sistema; Android lo ignora.",
    ),
    "yearsAgo": m96,
    "yearsAgoShort": m97,
    "yes": MessageLookupByLibrary.simpleMessage("Sí"),
    "zhCN": MessageLookupByLibrary.simpleMessage("Chino simplificado"),
  };
}
