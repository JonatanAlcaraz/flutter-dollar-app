import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ExchangeRate {
  final String title;
  final double valueSell;
  final double valueBuy;

  ExchangeRate({
    required this.title,
    required this.valueSell,
    required this.valueBuy,
  });
}


class ExchangeData {
  Map<String, dynamic> data;
  DateTime lastUpdate;

  ExchangeData({
    required this.data,
    required this.lastUpdate,
  });
}

Future<ExchangeData> fetchExchangeData() async {
  final response = await http.get(Uri.parse('https://api.bluelytics.com.ar/v2/latest'));
  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    final lastUpdate = DateTime.parse(jsonData['last_update']);

    final exchangeData = ExchangeData(
      data: jsonData,
      lastUpdate: lastUpdate,
    );

    return exchangeData;
  } else {
    throw Exception('Error de conexión');
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ExchangeData exchangeData = ExchangeData(data: {}, lastUpdate: DateTime.now());
  double valorIngresado = 0.0;
  double resultado = 0.0;
  String opcionSeleccionada = 'Dólar';
  
  void actualizarDatos() async {
    var response = await http.get(Uri.parse('https://api.bluelytics.com.ar/v2/latest'));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        exchangeData.data = data;
        exchangeData.lastUpdate = DateTime.parse(data['last_update']);
      });
    } else {
      // Error si la actualizacion no se completa
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('No se pudo actualizar los datos. Por favor, intenta nuevamente.'),
          actions: [
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void actualizarValorIngresado(double valor, Map<String, dynamic> jsonData) {
  setState(() {
    valorIngresado = valor;
    if (opcionSeleccionada == 'Dólar') {
      resultado = valorIngresado * jsonData['oficial']['value_sell'];
    } else {
      resultado = valorIngresado * jsonData['oficial_euro']['value_sell'];
    }
  });
}



  Future<ExchangeData> _getExchangeData() async {
    final exchangeData = await fetchExchangeData();
    return exchangeData;
  }

  Widget _buildExchangeCard(String title, double valueSell, double valueBuy) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Valor de compra: $valueBuy'),
          Text('Valor de venta: $valueSell'),
          SizedBox(height: 16),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('La cuevita 💵'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              actualizarDatos();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
  child: Column(
    children: [
      // Parte de la API

      FutureBuilder<ExchangeData>(
        future: _getExchangeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final exchangeData = snapshot.data!;
            final jsonData = exchangeData.data;
            final lastUpdate = exchangeData.lastUpdate;
            final formattedDateTime = DateFormat('dd MM yyyy HH:mm').format(lastUpdate);

            // Calculadora
            double resultado;
            if (opcionSeleccionada == 'Dólar') {
              resultado = valorIngresado * jsonData['oficial']['value_sell'];
            } else {
              resultado = valorIngresado * jsonData['oficial_euro']['value_sell'];
            }

            return Column(
              children: [
                _buildExchangeCard(
                  'Dolar Oficial',
                  jsonData['oficial']['value_sell'],
                  jsonData['oficial']['value_buy'],
                ),
                _buildExchangeCard(
                  'Dolar Blue',
                  jsonData['blue']['value_sell'],
                  jsonData['blue']['value_buy'],
                ),
                _buildExchangeCard(
                  'Oficial Euro',
                  jsonData['oficial_euro']['value_sell'],
                  jsonData['oficial_euro']['value_buy'],
                ),
                _buildExchangeCard(
                  'Blue Euro',
                  jsonData['blue_euro']['value_sell'],
                  jsonData['blue_euro']['value_buy'],
                ),
                SizedBox(height: 16),
                Text(
                  'Última actualización: $formattedDateTime',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Calculadora
                Container(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Calculadora',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Ingrese un valor',
                        ),
                        onChanged: (value) {
                          actualizarValorIngresado(double.tryParse(value) ?? 0.0, jsonData);
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Resultado: $resultado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Text('No hay datos disponibles');
          }
        },
      ),
    ],
  ),
),
    ));
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exchange Rates',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF013510, {
                        50: Color(0xFFE6F5E4),
                        100: Color(0xFFC0E7BF),
                        200: Color(0xFF9AD896),
                        300: Color(0xFF74CA6C),
                        400: Color(0xFF4EBC43),
                        500: Color(0xFF28AD1A),
                        600: Color(0xFF1F8D14),
                        700: Color(0xFF176B0E),
                        800: Color(0xFF0E4908),
                        900: Color(0xFF052704),
                      }),
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}
