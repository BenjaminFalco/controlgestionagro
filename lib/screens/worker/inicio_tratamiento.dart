import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controlgestionagro/services/global_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'formulario_tratamiento.dart';
import '../login_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:controlgestionagro/models/tratamiento_local.dart';
import 'package:controlgestionagro/services/offline_sync_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:controlgestionagro/models/users_local.dart';
import 'package:controlgestionagro/services/global_services.dart';

class InicioTratamientoScreen extends StatefulWidget {
  const InicioTratamientoScreen({super.key});

  @override
  State<InicioTratamientoScreen> createState() =>
      _InicioTratamientoScreenState();
}

class _InicioTratamientoScreenState extends State<InicioTratamientoScreen> {
  String? ciudadSeleccionada;
  String? serieSeleccionada;
  String? bloqueSeleccionado;
  String? parcelaSeleccionada;

  UsuarioLocal? usuarioActual;
  // ⬅️ Variable de instancia en tu clase State
  String uid =
      'default'; // ⬅️ Ya declarada en tu State (según lo que mencionas)

  List<dynamic> ciudades = [];
  List<dynamic> series = [];
  List<String> bloques = [];
  List<dynamic> parcelas = [];

  String numeroFicha = '';
  String numeroTratamiento = '';
  final TextEditingController superficieController = TextEditingController(
    text: "10",
  );

  @override
  void initState() {
    super.initState();
    cargarTodoAlInicio();
  }

  Future<void> cargarTodoAlInicio() async {
    final hayConexion = await _hasConexion();
    final db = GlobalServices.syncService.db;

    if (hayConexion) {
      // 🔹 1. Sincronizar ciudades
      await GlobalServices.syncService.fetchAndCacheCollection(
        firestorePath: 'ciudades',
        tableName: 'ciudades',
        docIdFn: (doc) => doc.id,
        mapFn:
            (doc) => {
              'ciudadId': doc.id,
              'nombre': doc['nombre'] ?? '',
              'fecha_creacion': doc['fecha_creacion']?.toString() ?? '',
            },
      );
    }

    final ciudadesRes = await db.query('ciudades');
    final ciudad = ciudadesRes.isNotEmpty ? ciudadesRes.first : null;
    if (ciudad == null) return;
    final ciudadId = ciudad['ciudadId'] as String;
    ciudadSeleccionada = ciudadId;

    // 🔹 2. Sincronizar series (si hay conexión)
    if (hayConexion) {
      await GlobalServices.syncService.fetchAndCacheCollection(
        firestorePath: 'ciudades/$ciudadId/series',
        tableName: 'series',
        docIdFn: (doc) => doc.id,
        mapFn:
            (doc) => {
              'serieId': doc.id,
              'ciudadId': ciudadId,
              'nombre': doc['nombre'] ?? '',
              'superficie': (doc['superficie'] ?? 10).toDouble(),
              'fecha_creacion': doc['fecha_creacion']?.toString() ?? '',
              'fecha_cosecha': doc['fecha_cosecha']?.toString() ?? '',
              'matriz_alto': doc['matriz_alto'] ?? 0,
              'matriz_largo': doc['matriz_largo'] ?? 0,
            },
      );
    }

    final seriesRes = await db.query(
      'series',
      where: 'ciudadId = ?',
      whereArgs: [ciudadId],
    );

    final serieId =
        seriesRes.isNotEmpty ? seriesRes.first['serieId'] as String : null;

    List<Map<String, Object?>> bloquesRes = [];
    List<Map<String, Object?>> parcelasRes = [];
    String? bloqueId;
    String? parcelaId;

    if (serieId != null) {
      if (hayConexion) {
        await GlobalServices.syncService.fetchAndCacheCollection(
          firestorePath: 'ciudades/$ciudadId/series/$serieId/bloques',
          tableName: 'bloques',
          docIdFn: (doc) => doc.id,
          mapFn:
              (doc) => {
                'bloqueId': doc.id,
                'serieId': serieId,
                'nombre': doc['nombre'] ?? '',
              },
        );
      }

      bloquesRes = await db.query(
        'bloques',
        where: 'serieId = ?',
        whereArgs: [serieId],
      );

      if (bloquesRes.isNotEmpty) {
        bloqueId = bloquesRes.first['bloqueId'] as String;

        if (hayConexion) {
          await GlobalServices.syncService.fetchAndCacheCollection(
            firestorePath:
                'ciudades/$ciudadId/series/$serieId/bloques/$bloqueId/parcelas',
            tableName: 'parcelas',
            docIdFn: (doc) => doc.id,
            mapFn:
                (doc) => {
                  'parcelaId': doc.id,
                  'bloqueId': bloqueId,
                  'numero': doc['numero'] ?? 0,
                  'numero_tratamiento': doc['numero_tratamiento'] ?? 0,
                  'numero_ficha': doc['numero_ficha'] ?? '',
                  'tratamiento': (doc['tratamiento'] ?? false) ? 1 : 0,
                  'trabajador_id': doc['trabajador_id'] ?? '',
                  'total_raices': doc['total_raices'] ?? 0,
                },
          );
        }

        parcelasRes = await db.query(
          'parcelas',
          where: 'bloqueId = ?',
          whereArgs: [bloqueId],
        );

        if (parcelasRes.isNotEmpty) {
          parcelaId = parcelasRes.first['parcelaId'] as String;
        }
      }

      print('📍 ciudades: ${ciudades.length}');
      print('📍 series: ${series.length}');
      print('📍 bloques: ${bloques.length}');
      print('📍 parcelas: ${parcelas.length}');
      print('📍 ciudadSeleccionada: $ciudadSeleccionada');
      print('📍 serieSeleccionada: $serieSeleccionada');
      print('📍 bloqueSeleccionado: $bloqueSeleccionado');
      print('📍 parcelaSeleccionada: $parcelaSeleccionada');
    }

    // ✅ setState final, independiente de si hay series o bloques
    setState(() {
      ciudadSeleccionada = ciudadId;
      serieSeleccionada = serieId;
      bloqueSeleccionado = bloqueId;
      parcelaSeleccionada = parcelaId;

      ciudades =
          ciudadesRes
              .map((e) => QueryDocumentSnapshotFake(e['ciudadId'] as String, e))
              .toList();
      series =
          seriesRes
              .map((e) => QueryDocumentSnapshotFake(e['serieId'] as String, e))
              .toList();
      bloques = bloquesRes.map((e) => e['bloqueId'].toString()).toList();
      parcelas =
          parcelasRes
              .map(
                (e) => QueryDocumentSnapshotFake(e['parcelaId'] as String, e),
              )
              .toList();
    });

    if (hayConexion) {
      await sincronizarTodoDesdeInicioTratamiento();
    }
  }

  Future<UsuarioLocal?> getUsuarioLocal() async {
    final db = GlobalServices.syncService.db;

    try {
      final result = await db.query('usuarios_locales', limit: 1);
      if (result.isNotEmpty) {
        return UsuarioLocal.fromMap(result.first);
      }
    } catch (e) {
      print('❌ Error obteniendo usuario local: $e');
    }

    return null;
  }

  Future<void> obtenerUidUsuario() async {
    final usuario = await getUsuarioLocal();

    setState(() {
      usuarioActual = usuario;
      uid = usuario?.uid ?? 'default';
    });
  }

  Future<bool> _hasConexion() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> guardarSuperficieEnSerie() async {
    if (ciudadSeleccionada == null || serieSeleccionada == null) return;

    final usuario = await getUsuarioLocal();
    final uid = usuario?.uid ?? 'default';

    final superficie = superficieController.text.trim();
    final db = GlobalServices.syncService.db;
    final hayConexion = await _hasConexion();

    try {
      // 🔁 Actualiza localmente en SQLite (sincronización pendiente)
      await db.update(
        'series',
        {
          'superficie': superficie,
          'isSynced': 0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        where: 'serieId = ?',
        whereArgs: [serieSeleccionada, ciudadSeleccionada],
      );

      print("✅ Superficie guardada localmente en SQLite");

      if (hayConexion) {
        // 🔁 Actualiza también en Firestore
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada!)
            .collection('series')
            .doc(serieSeleccionada!)
            .update({'superficie': superficie});

        // ✅ Marca como sincronizado
        await db.update(
          'series',
          {'isSynced': 1},
          where: 'serieId = ? ',
          whereArgs: [serieSeleccionada, ciudadSeleccionada],
        );

        print("✅ Superficie sincronizada con Firestore");
      }
    } catch (e) {
      print("❌ Error al guardar superficie: $e");
    }
  }

  Future<void> sincronizarTodoDesdeInicioTratamiento() async {
    final ciudadId = ciudadSeleccionada;

    if (ciudadId == null || ciudadId.isEmpty) {
      print('⚠️ No se puede sincronizar sin ciudadId seleccionada');
      return;
    }

    final sync = GlobalServices.syncService;

    // 🔄 Sincronizar series de la ciudad seleccionada
    await sync.sincronizarPendientes(
      tableName: 'series',
      idFieldName: 'serieId',
      parentPathBuilder: (_) => 'ciudades/$ciudadId/series',
    );

    // 🔄 Sincronizar bloques anidados por serie
    await sync.sincronizarPendientes(
      tableName: 'bloques',
      idFieldName: 'bloqueId',
      parentPathBuilder:
          (row) => 'ciudades/$ciudadId/series/${row['serieId']}/bloques',
    );

    // 🔄 Sincronizar parcelas anidadas por bloque
    await sync.sincronizarPendientes(
      tableName: 'parcelas',
      idFieldName: 'parcelaId',
      parentPathBuilder:
          (row) =>
              'ciudades/$ciudadId/series/${row['serieId']}/bloques/${row['bloqueId']}/parcelas',
    );
  }

  Future<void> sincronizarPendientesSeries() async {
    final connected = await _hasConexion();
    if (!connected) return;

    final db = GlobalServices.syncService.db;
    final usuario = await getUsuarioLocal();
    final uid = usuario?.uid ?? 'default';

    try {
      final pendientes = await db.query(
        'series',
        where: 'isSynced = 0',
        whereArgs: [uid],
      );

      for (final row in pendientes) {
        final ciudadId = row['ciudadId']?.toString() ?? '';
        final serieId = row['serieId']?.toString() ?? '';
        final superficie = row['superficie']?.toString() ?? '10';

        try {
          // 🔁 Actualiza en Firestore
          await FirebaseFirestore.instance
              .collection('ciudades')
              .doc(ciudadId)
              .collection('series')
              .doc(serieId)
              .update({'superficie': superficie});

          // ✅ Marca como sincronizado
          await db.update(
            'series',
            {'isSynced': 1},
            where: 'serieId = ?',
            whereArgs: [serieId, ciudadId],
          );

          print("✅ Sincronizada serie $serieId");
        } catch (e) {
          print("❌ Falló sincronización de $serieId: $e");
        }
      }
    } catch (e) {
      print("❌ Error general al sincronizar series: $e");
    }
  }

  Future<void> cargarCiudades() async {
    final hayConexion = await _hasConexion();
    final table = 'ciudades';

    if (hayConexion) {
      //ONLINE
      await GlobalServices.syncService.fetchAndCacheCollection(
        firestorePath: 'ciudades',
        tableName: table,
        docIdFn: (doc) => doc.id,
        mapFn:
            (doc) => {
              'ciudadId': doc.id,
              'nombre': doc['nombre'] ?? '',
              'fecha_creacion': doc['fecha_creacion']?.toString() ?? '',
            },
      );
    }
    //OFFLINE
    final result = await GlobalServices.syncService.db.query(table);
    setState(() {
      ciudades =
          result
              .map((e) => QueryDocumentSnapshotFake(e['ciudadId'] as String, e))
              .toList();
    });
  }

  Future<void> cargarSuperficieDesdeSerie() async {
    if (serieSeleccionada == null) return;

    try {
      final result = await GlobalServices.syncService.db.query(
        'series',
        where: 'serieId = ?',
        whereArgs: [serieSeleccionada],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final superficie = result.first['superficie']?.toString() ?? '10';
        superficieController.text = superficie;
      } else {
        superficieController.text = '10';
      }
    } catch (e) {
      print('❌ Error cargando superficie: $e');
      superficieController.text = '10';
    }
  }

  Future<void> cargarSeries() async {
    if (ciudadSeleccionada == null) return;

    final hayConexion = await _hasConexion();
    final table = 'series';

    if (hayConexion) {
      await GlobalServices.syncService.fetchAndCacheCollection(
        firestorePath: 'ciudades/$ciudadSeleccionada/series',
        tableName: table,
        docIdFn: (doc) => doc.id,
        mapFn:
            (doc) => {
              'serieId': doc.id,
              'ciudadId': ciudadSeleccionada,
              'nombre': doc['nombre'] ?? '',
              'superficie': (doc['superficie'] ?? 10).toDouble(),
              'fecha_creacion': doc['fecha_creacion']?.toString() ?? '',
              'fecha_cosecha': doc['fecha_cosecha']?.toString() ?? '',
              'matriz_alto': doc['matriz_alto'] ?? 0,
              'matriz_largo': doc['matriz_largo'] ?? 0,
              'isSynced': 1,
              'timestamp': DateTime.now().toIso8601String(),
            },
      );
    }

    final result = await GlobalServices.syncService.db.query(
      table,
      where: 'ciudadId = ?',
      whereArgs: [ciudadSeleccionada],
    );

    print('🔍 SERIES ENCONTRADAS EN SQLITE: ${result.length}');
    for (var row in result) {
      print('🧪 serieId: ${row['serieId']} | ciudadId: ${row['ciudadId']}');
    }

    setState(() {
      series =
          result
              .map((e) => QueryDocumentSnapshotFake(e['serieId'] as String, e))
              .toList();
    });
  }

  Future<void> cargarBloques() async {
    if (serieSeleccionada == null) return;

    final hayConexion = await _hasConexion();
    final table = 'bloques';

    if (hayConexion) {
      await GlobalServices.syncService.fetchAndCacheCollection(
        firestorePath: 'series/$serieSeleccionada/bloques',
        tableName: table,
        docIdFn: (doc) => doc.id,
        mapFn:
            (doc) => {
              'bloqueId': doc.id,
              'serieId': serieSeleccionada,
              'nombre': doc['nombre'] ?? '',
              'isSynced': 1,
              'timestamp': DateTime.now().toIso8601String(),
            },
      );
    }

    final result = await GlobalServices.syncService.db.query(
      table,
      where: 'serieId = ?',
      whereArgs: [serieSeleccionada],
    );

    setState(() {
      bloques = result.map((e) => e['bloqueId'].toString()).toList();
    });
  }

  ////cargar Parcelas

  Future<void> cargarParcelas() async {
    if (bloqueSeleccionado == null) return;

    final hayConexion = await _hasConexion();
    final table = 'parcelas';

    if (hayConexion) {
      await GlobalServices.syncService.fetchAndCacheCollection(
        firestorePath: 'bloques/$bloqueSeleccionado/parcelas',
        tableName: table,
        docIdFn: (doc) => doc.id,
        mapFn:
            (doc) => {
              'parcelaId': doc.id,
              'bloqueId': bloqueSeleccionado,
              'numero': doc['numero'] ?? 0,
              'numero_tratamiento': doc['numero_tratamiento'] ?? 0,
              'numero_ficha': doc['numero_ficha'] ?? '',
              'tratamiento': (doc['tratamiento'] ?? false) ? 1 : 0,
              'trabajador_id': doc['trabajador_id'] ?? '',
              'total_raices': doc['total_raices'] ?? 0,
              'isSynced': 1,
              'timestamp': DateTime.now().toIso8601String(),
            },
      );
    }

    final result = await GlobalServices.syncService.db.query(
      table,
      where: 'bloqueId = ?',
      whereArgs: [bloqueSeleccionado],
      orderBy: 'numero ASC',
    );

    setState(() {
      parcelas =
          result
              .map(
                (e) => QueryDocumentSnapshotFake(e['parcelaId'] as String, e),
              )
              .toList();
    });
  }

  Future<void> actualizarInfoParcela(String id) async {
    final doc = parcelas.firstWhere((p) => p.id == id);
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null || !data.containsKey('numero_tratamiento')) {
      setState(() {
        numeroFicha = '';
        numeroTratamiento = '';
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Campo faltante"),
              content: const Text(
                "Las parcelas de este bloque no tienen asignado el campo 'número de tratamiento'.\n\nPor favor, pide al administrador que lo genere antes de continuar.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      numeroFicha = data['numero_ficha']?.toString() ?? '';
      numeroTratamiento = data['numero_tratamiento']?.toString() ?? '';
    });
  }

  Future<bool> puedeGenerarNumerosFicha() async {
    if (bloqueSeleccionado != 'A' || parcelaSeleccionada == null) return false;

    final doc = parcelas.firstWhere((p) => p.id == parcelaSeleccionada);
    final numeroParcela = doc['numero'];
    if (numeroParcela != 1) return false;

    final bloquesSnapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada!)
            .collection('series')
            .doc(serieSeleccionada!)
            .collection('bloques')
            .get();

    for (var bloqueDoc in bloquesSnapshot.docs) {
      final parcelasSnapshot =
          await bloqueDoc.reference
              .collection('parcelas')
              .where('numero_ficha', isGreaterThanOrEqualTo: 1)
              .limit(1)
              .get();
      if (parcelasSnapshot.docs.isNotEmpty) return false;
    }

    return true;
  }

  Future<void> generarNumerosFicha(int numeroInicial) async {
    int contador = numeroInicial;

    final bloquesSnapshot =
        await FirebaseFirestore.instance
            .collection('ciudades')
            .doc(ciudadSeleccionada!)
            .collection('series')
            .doc(serieSeleccionada!)
            .collection('bloques')
            .orderBy(FieldPath.documentId)
            .get();

    for (var bloqueDoc in bloquesSnapshot.docs) {
      final parcelasSnapshot =
          await bloqueDoc.reference
              .collection('parcelas')
              .orderBy('numero')
              .get();

      for (var parcelaDoc in parcelasSnapshot.docs) {
        await parcelaDoc.reference.update({'numero_ficha': contador});
        contador++;
      }
    }

    await cargarParcelas(); // Refresca la UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Números de ficha generados exitosamente"),
      ),
    );
  }

  void mostrarModalGenerarFicha() async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Ingresar número inicial de ficha"),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Ej: 100"),
            ),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Generar"),
                onPressed: () {
                  final input = int.tryParse(controller.text.trim());
                  if (input != null) {
                    Navigator.pop(context);
                    generarNumerosFicha(input);
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> iniciarTratamiento() async {
    if (ciudadSeleccionada == null ||
        serieSeleccionada == null ||
        parcelaSeleccionada == null)
      return;

    await guardarSuperficieEnSerie();

    final doc = parcelas.firstWhere((p) => obtenerId(p) == parcelaSeleccionada);
    final numeroTratamiento = obtenerCampo(doc, 'numero_tratamiento');
    final numeroFicha = obtenerCampo(doc, 'numero_ficha');
    final numeroParcela = int.tryParse(obtenerCampo(doc, 'numero')) ?? 0;

    if (numeroTratamiento.isEmpty) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text("Falta número de tratamiento"),
              content: const Text(
                "Esta parcela no tiene asignado el número de tratamiento. Por favor, pide al administrador que lo genere.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FormularioTratamiento(
              ciudadId: ciudadSeleccionada!,
              serieId: serieSeleccionada!,
              bloqueId: bloqueSeleccionado ?? '1',
              parcelaDesde: numeroParcela,
              numeroFicha: numeroFicha,
              numeroTratamiento: numeroTratamiento,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 70,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          tooltip: "Refrescar datos",
          onPressed: () async {
            await cargarCiudades();
            await cargarSeries();
            await cargarBloques();
            await cargarParcelas();

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Datos actualizados"),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        centerTitle: true,
        title: const Text(
          "POSICIONAR TERRENO",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: "Cerrar sesión",
            onPressed: () async {
              await GlobalServices.syncService.db.delete('usuarios_locales');

              // 🔐 también cerrar sesión de Firebase si está online
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 34),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Localidad",
                                ciudadSeleccionada,
                                ciudades.map((doc) {
                                  return DropdownMenuItem(
                                    value: obtenerId(doc),
                                    child: Text(
                                      obtenerCampo(doc, 'nombre'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                (value) async {
                                  setState(() {
                                    ciudadSeleccionada = value;
                                    serieSeleccionada = null;
                                    bloqueSeleccionado = null;
                                    parcelaSeleccionada = null;
                                    series.clear();
                                    bloques.clear();
                                    parcelas.clear();
                                  });

                                  await cargarSeries(); // Carga asincrónica dependiente de ciudadSeleccionada

                                  setState(
                                    () {},
                                  ); // Fuerza reconstrucción luego de que `series` se cargue
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 35),
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Ensayo",
                                serieSeleccionada,
                                series.map((doc) {
                                  return DropdownMenuItem(
                                    value: obtenerId(doc),
                                    child: Text(
                                      obtenerCampo(doc, 'nombre'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                (value) async {
                                  setState(() {
                                    serieSeleccionada = value;
                                    bloqueSeleccionado = null;
                                    parcelaSeleccionada = null;
                                    bloques.clear();
                                    parcelas.clear();
                                  });

                                  await cargarBloques(); // Depende de serieSeleccionada
                                  await cargarSuperficieDesdeSerie();

                                  setState(
                                    () {},
                                  ); // Reconstruye con bloques ya cargados
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 🔹 Bloque y Tratamiento de inicio
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Bloque",
                                bloqueSeleccionado,
                                bloques.map((b) {
                                  return DropdownMenuItem(
                                    value: b,
                                    child: Text(
                                      "Bloque $b",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                (value) async {
                                  setState(() {
                                    bloqueSeleccionado = value;
                                    parcelaSeleccionada = null;
                                    parcelas.clear();
                                  });

                                  await cargarParcelas(); // Depende de bloqueSeleccionado

                                  setState(
                                    () {},
                                  ); // Refresca las parcelas luego de la carga
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildFieldBox(
                              _buildDropdown(
                                "Tratamiento de inicio",
                                parcelaSeleccionada,
                                parcelas.map((doc) {
                                  return DropdownMenuItem(
                                    value: obtenerId(doc),
                                    child: Text(
                                      "T ${obtenerCampo(doc, 'numero_tratamiento')}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                (value) {
                                  setState(() {
                                    parcelaSeleccionada = value;
                                  });

                                  if (value != null) {
                                    actualizarInfoParcela(
                                      value,
                                    ); // Esta puede ser async si lo deseas
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFieldBox(
                        Row(
                          children: [
                            // Campo de número editable
                            Expanded(
                              child: TextField(
                                controller: superficieController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Superficie cosechable",
                                  hintStyle: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const Text(
                              "m²",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      FutureBuilder<bool>(
                        future: puedeGenerarNumerosFicha(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox(); // o loader
                          }

                          if (snapshot.data == true) {
                            return Column(
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: mostrarModalGenerarFicha,
                                    icon: const Icon(
                                      Icons.auto_fix_high,
                                      size: 34,
                                    ),
                                    label: const Text(
                                      "GENERAR N° FICHA",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              parcelaSeleccionada != null
                                  ? iniciarTratamiento
                                  : null,
                          icon: const Icon(Icons.play_arrow, size: 34),
                          label: const Text(
                            "INICIAR TOMA DE DATOS",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF04bc04),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    Function(String?) onChanged,
  ) {
    final validValues = items.map((item) => item.value).toList();
    final fixedValue = validValues.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: fixedValue, // usa el valor fijo corregido
      isExpanded: true,
      dropdownColor: Colors.black,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: Colors.black,
        border: InputBorder.none,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 22),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildFieldBox(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white, width: 10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
  }
}

QueryDocumentSnapshotFake _mapToQuerySnapshot(Map<String, dynamic> map) {
  return QueryDocumentSnapshotFake(map['id']?.toString() ?? '', map);
}

class QueryDocumentSnapshotFake {
  final String id;
  final Map<String, dynamic> _data;

  QueryDocumentSnapshotFake(this.id, this._data);

  Map<String, dynamic> data() => _data;

  dynamic operator [](String key) => _data[key];
}

String obtenerCampo(dynamic doc, String campo) {
  try {
    if (doc is Map<String, dynamic>) return doc[campo]?.toString() ?? '';
    if (doc is QueryDocumentSnapshotFake) {
      return doc.data()[campo]?.toString() ?? '';
    }
    if (doc is QueryDocumentSnapshot || doc is DocumentSnapshot) {
      return (doc.data() as Map<String, dynamic>)[campo]?.toString() ?? '';
    }
  } catch (_) {}
  return '';
}

String obtenerId(dynamic doc) {
  try {
    if (doc is Map<String, dynamic>) {
      // Buscar clave terminada en Id
      return doc['serieId']?.toString() ??
          doc['bloqueId']?.toString() ??
          doc['parcelaId']?.toString() ??
          doc['ciudadId']?.toString() ??
          '';
    }
    if (doc is QueryDocumentSnapshotFake) return doc.id;
    if (doc is QueryDocumentSnapshot || doc is DocumentSnapshot) {
      return doc.id;
    }
  } catch (_) {}
  return '';
}
