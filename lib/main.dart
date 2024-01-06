import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';
import 'parking.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estacionamientos',
      theme: ThemeData(
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ParkingScreen(),
    );
  }
}

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({Key? key}) : super(key: key);

  @override
  _ParkingScreenState createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  final Color primaryColor = const Color.fromARGB(255, 68, 102, 196);
  Future<List<Parking>>? parkingsFuture;
  final apiService = ApiService();
  int _selectedIndex = 1;
  double _selectedLat = -36.828686;
  double _selectedLong = -73.037294;
  String? selectedUserType;
  Timer? _timer;
  DateTime? lastUpdated;
  bool _isMapLoading = true;
  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    parkingsFuture = apiService.fetchParkings();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (Timer timer) => _refreshData(),
    );
  }

  void _refreshData() {
    setState(() {
      parkingsFuture = apiService.fetchParkings();
      lastUpdated = DateTime.now();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navegarAlMapaYCentrar(double lat, double long) {
    setState(() {
      _selectedLat = lat;
      _selectedLong = long;
      _selectedIndex = 0;
      _isMapLoading = true;
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Buenos días!';
    } else if (hour >= 12 && hour < 18) {
      return 'Buenas tardes!';
    } else {
      return 'Buenas noches!';
    }
  }

  Widget _buildCheckboxListTile(String title, String value) {
    return ListTileTheme(
      contentPadding: EdgeInsets.zero,
      child: CheckboxListTile(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(title),
        ),
        value: selectedUserType == value,
        onChanged: (bool? checked) => _updateSelectedUserType(value),
        activeColor: primaryColor,
      ),
    );
  }

  void _updateSelectedUserType(String value) {
    setState(() {
      selectedUserType = selectedUserType == value ? null : value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildDrawerHeader(),
            ..._buildRoleList(),
          ],
        ),
      ),
      body: _buildBodyWithGesture(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 68, 102, 196),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/images/campanil.jpg',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15.0, 40.0, 15.0, 0.0),
                  child: Text(
                    getGreetingMessage(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text(
                    'Seleccione su rol en la universidad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleList() {
    const roles = ['\tAcadémico', '\tEstudiante', '\tAdministrativo', '\tOtro'];
    const roleValues = ['academico', 'estudiante', 'administrativo', 'otro'];

    return List<Widget>.generate(
      roles.length,
      (index) => Column(
        children: [
          _buildCheckboxListTile(roles[index], roleValues[index]),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildBodyWithGesture() {
    // Variables para controlar la posición inicial del gesto.
    double startDragX = 0.0;
    bool dragFromRightQuarter = false;

    return Listener(
      onPointerDown: (PointerDownEvent event) {
        // Marcar el inicio del gesto y si comienza en el último cuarto derecho de la pantalla.
        startDragX = event.position.dx;
        dragFromRightQuarter =
            startDragX > MediaQuery.of(context).size.width * 0.75;
      },
      onPointerMove: (PointerMoveEvent event) {
        // Comprobar si el gesto continúa desde el último cuarto derecho de la pantalla.
        if (dragFromRightQuarter) {
          // Determinar si el movimiento actual es hacia la izquierda.
          if (event.delta.dx < 0) {
            // Abrir el drawer si el desplazamiento horizontal es suficiente hacia la izquierda.
            if (event.position.dx < startDragX - 50) {
              // 50 es un umbral de desplazamiento, puede ser ajustado.
              _scaffoldKey.currentState?.openEndDrawer();
              dragFromRightQuarter = false;
              startDragX = 0.0;
            }
          }
        }
      },
      onPointerUp: (PointerUpEvent event) {
        // Resetear las variables al finalizar el gesto.
        dragFromRightQuarter = false;
        startDragX = 0.0;
      },
      child: _buildBody(),
    );
  }

  final Set<Marker> _markers = {};

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return FutureBuilder<List<Parking>>(
          future: parkingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  _getErrorMessage(snapshot.error),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              _markers.clear();
              _addMarkers(snapshot.data!);
              return Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_selectedLat, _selectedLong),
                      zoom: 17.0,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      Future.delayed(
                          const Duration(seconds: 0, milliseconds: 500), () {
                        setState(() {
                          _isMapLoading = false; // Mapa cargado
                        });
                      });
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    myLocationEnabled: true,
                  ),
                  // Bloqueo cuando el mapa esté cargando
                  _isMapLoading
                      ? Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              color: Colors.black.withOpacity(0.4),
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                          ),
                        )
                      : Container(),
                ],
              );
            } else {
              return const Center(
                child: Text('No hay datos disponibles'),
              );
            }
          },
        );
      case 1:
        return _buildCustomScrollView();
      default:
        return Container();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'No hay conexión a Internet';
    } else if (error is ServerException) {
      return 'Error al obtener datos del servidor';
    } else {
      return 'Ocurrió un error';
    }
  }

  void _addMarkers(List<Parking> parkings) {
    for (Parking parking in parkings) {
      if (parking.getCategory(selectedUserType)) {
        _markers.add(
          Marker(
            markerId: MarkerId(parking.id.toString()),
            position: parking.latLng,
            infoWindow: InfoWindow(
              title: parking.pkName,
              snippet: 'Espacios libres: ${parking.freeSpaces}',
            ),
          ),
        );
      }
    }
  }

  Widget _buildCustomScrollView() {
    return CustomScrollView(
      slivers: <Widget>[
        _buildSliverAppBar(),
        _buildSliverPadding(),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    // Obtener dimensiones de pantalla
    double screenHeight = MediaQuery.of(context).size.height;

    // Calcular dimensiones adaptadas
    double toolbarHeight =
        screenHeight * 0.10; // 10% de la altura de la pantalla
    double expandedHeight =
        screenHeight * 0.20; // 20% de la altura de la pantalla

    return SliverAppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      title: Text(
        "Estaciona UdeC",
        style: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
          ),
        ),
      ),
      pinned: true,
      floating: true,
      expandedHeight: expandedHeight,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: constraints.maxHeight > toolbarHeight
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    )
                  : null,
            ),
            child: _buildFlexibleSpaceBar(),
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              lastUpdated != null
                  ? 'Última actualización: ${lastUpdated!.toLocal().toIso8601String().substring(11, 19)}'
                  : 'Obteniendo última actualización...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlexibleSpaceBar() {
    return FlexibleSpaceBar(
      titlePadding: const EdgeInsetsDirectional.only(
          start: 16, bottom: 16),
      background: Container(
        decoration: BoxDecoration(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30)),
          color: primaryColor,
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(30)),
          child: Stack(
            fit: StackFit.expand, // Asegura que la Stack cubra todo el espacio
            children: [
              // Imagen con opacidad
              Opacity(
                opacity:
                    0.3,
                child: Image.asset(
                  'assets/images/arco_udec.png',
                  fit: BoxFit
                      .fill, // Esto debería hacer que la imagen cubra todo el espacio disponible
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverPadding() {
    return SliverPadding(
      padding: const EdgeInsets.all(10.0),
      sliver: FutureBuilder<List<Parking>>(
        key: ValueKey<DateTime>(DateTime.now()), // Añadir esta línea
        future: parkingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return SliverFillRemaining(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            // Ordenamos los datos por el nombre del estacionamiento (pkName)
            final sortedData = snapshot.data!
              ..sort((a, b) => a.pkName.compareTo(b.pkName));

            // Filtramos los datos según la categoría seleccionada
            final filteredData = sortedData
                .where((parking) => parking.getCategory(selectedUserType))
                .toList();

            return SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final parking = filteredData[index];
                  return ParkingCard(
                    parking: parking,
                    onMapButtonPressed: _navegarAlMapaYCentrar,
                  );
                },
                childCount: filteredData.length,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50), // Define bordes redondeados.
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
            10), // Esto asegura que la barra no sobresalga del contenedor.
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors
              .transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (!(_isMapLoading && index == 1)) {
              // Previene navegar al mapa mientras está cargando
              setState(() => _selectedIndex = index);
              setState(() => _isMapLoading = true);
            }
          },
          iconSize: 30.0,
          selectedFontSize: 16.0,
          unselectedFontSize: 14.0,
          type: BottomNavigationBarType.shifting,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                color: primaryColor, // Color azul aquí
                child: const Icon(Icons.map),
              ),
              label: 'Mapa',
              backgroundColor: primaryColor,
            ),
            BottomNavigationBarItem(
              icon: Container(
                color: primaryColor,
                child: const Icon(Icons.list_sharp),
              ),
              label: 'Estacionamientos',
              backgroundColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class ParkingCard extends StatelessWidget {
  final Parking parking;
  final Function(double, double) onMapButtonPressed;

  const ParkingCard({
    Key? key,
    required this.parking,
    required this.onMapButtonPressed,
  }) : super(key: key);

  void _navigateToMapAndCenter() {
    onMapButtonPressed(parking.latitude, parking.longitude);
  }

  void _showLastUpdatedToast(BuildContext context) {
    final chileTimeZone = tz.getLocation('America/Santiago');
    final now = tz.TZDateTime.now(chileTimeZone);
    final lastUpdateChileTime =
        tz.TZDateTime.from(parking.lastUpdate, chileTimeZone)
            .add(const Duration(hours: 0));
    final difference = now.difference(lastUpdateChileTime);
    final formattedTime = _formatTimeDifference(difference);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizado hace $formattedTime'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatTimeDifference(Duration difference) {
    if (difference.inMinutes < 1) {
      return '${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutos';
    } else {
      return '${difference.inHours} horas';
    }
  }

  Color _getStatusColor(DateTime lastUpdate) {
    final chileTimeZone = tz.getLocation('America/Santiago');
    final lastUpdateChileTime = tz.TZDateTime.from(lastUpdate, chileTimeZone)
        .add(const Duration(hours: 0));
    final now = tz.TZDateTime.now(chileTimeZone);
    final difference = now.difference(lastUpdateChileTime);

    if (difference.inMinutes < 1) {
      return Colors.green;
    } else if (difference.inMinutes < 5) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;


    double titleFontSize = screenSize.width * 0.04;
    double spacesFontSize = screenSize.width * 0.07;
    double totalSpacesFontSize = screenSize.width * 0.045;
    double iconSize = screenSize.height *
        0.045; 
    double statusIndicatorSize = screenSize.width * 0.02;

    double cardPadding = screenSize.width *
        0.02;

    return InkWell(
      onTap: () => _showLastUpdatedToast(context),
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            margin: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.02,
              vertical: constraints.maxHeight * 0.01,
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          child: Text(
                            parking.pkName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          iconSize: iconSize,
                          icon:
                              const Icon(Icons.location_on, color: Colors.blue),
                          onPressed: _navigateToMapAndCenter,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${parking.freeSpaces}',
                                style: TextStyle(
                                  fontSize: spacesFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              TextSpan(
                                text: ' / ${parking.totalSpaces}',
                                style: TextStyle(
                                  fontSize: totalSpacesFontSize,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: statusIndicatorSize,
                        width: statusIndicatorSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(2),
                          color: _getStatusColor(parking.lastUpdate),
                        ),
                      ),
                      if (parking.reducedCapacity)
                        Icon(
                          Icons.accessible,
                          color: Colors.teal,
                          size: iconSize,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
