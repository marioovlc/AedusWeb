import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../lib/core/services/database_service.dart';

void main() async {
  final db = DatabaseService();
  try {
    print('Creating solicitudes_usuario table...');
    await db.query('''
      CREATE TABLE IF NOT EXISTS gestion_incidencias.solicitudes_usuario (
          id SERIAL PRIMARY KEY,
          nombre VARCHAR(100) NOT NULL,
          email VARCHAR(100) UNIQUE NOT NULL,
          password_hash VARCHAR(255) NOT NULL,
          motivo TEXT,
          fecha_solicitud TIMESTAMP DEFAULT NOW(),
          estado VARCHAR(20) DEFAULT 'PENDIENTE'
      );
    ''');
    print('Table created successfully!');
  } catch (e) {
    print('Error: \$e');
  }
}
