# AedusWeb

AedusWeb es una app hecha con Flutter para gestionar incidencias, comunicarse en tiempo real y trabajar en equipo. Usa un diseño oscuro y está pensada para uso profesional.

## Funciones
- Dashboard con métricas y gráficos
- IA para clasificar incidencias
- Chat y contactos
- Sistema de tickets con imágenes y estados
- Sistema de puntos y logros
- PostgreSQL + almacenamiento en la nube

## Tecnologías
Flutter · Provider · PostgreSQL · Groq · Font Awesome

## Ejecutar el proyecto

Clonar repo:
git clone https://github.com/YourUser/AedusWeb.git

Crear archivo `.env`:
DB_URL=tu_url
DB_USER=tu_user
DB_PASS=tu_pass
AI_API_KEY=tu_api_key
AI_MODEL=llama-3.3-70b-versatile

Instalar dependencias:
flutter pub get

Ejecutar:
flutter run