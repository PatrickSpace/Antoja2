# Antoja2

MVP personal para iOS que registra antojos mediante un chat. Antes de guardar, la IA muestra la comida estructurada, el rango de calorías y todos los supuestos usados; el usuario puede corregirlos conversando o registrar el borrador.

Cuatro horas después, una notificación recuerda resolver el antojo como **Lo comí** o **No lo comí**. La segunda opción exige una confirmación adicional. Las calorías se contabilizan como consumidas o evitadas únicamente al resolver el resultado. La sección **Progreso** agrupa las calorías evitadas por semana y las presenta como una colección visual con gráfico, XP, racha de seguimientos e insignias.

## Arquitectura del MVP

- **iOS:** SwiftUI, Google Sign-In, Firebase Auth, Firestore, Firebase Functions y notificaciones locales.
- **Backend:** una Callable Function autenticada mantiene la clave de OpenAI fuera de la app.
- **IA:** OpenAI Responses API con `gpt-5.6-luna` y Structured Outputs mediante JSON Schema estricto.
- **Datos:** `users/{uid}` y `users/{uid}/cravings/{cravingId}`. Las reglas permiten a cada cuenta leer y modificar solo sus documentos.
- **Estados del antojo:** `pending`, `consumed` y `avoided_confirmed`.

Flujo principal:

1. El usuario describe un antojo en el chat.
2. La Function interpreta la comida. Si falta una porción crítica, devuelve una pregunta concreta.
3. La app presenta porción, rango calórico y supuestos editables.
4. El usuario corrige por chat o registra el borrador como pendiente.
5. A las cuatro horas recibe un recordatorio y decide el resultado.

## Configuración

1. Abre `Antoja2.xcodeproj` en Xcode y permite que Swift Package Manager resuelva Firebase y Google Sign-In.
2. En Firebase Authentication, habilita únicamente el proveedor Google.
3. Crea Firestore en el proyecto `antoja2-271ed`.
4. Configura el secreto de OpenAI:

   ```sh
   firebase functions:secrets:set OPENAI_API_KEY
   ```

5. Instala y despliega las Functions y reglas:

   ```sh
   cd functions
   npm install
   cd ..
   firebase deploy --only functions,firestore:rules
   ```

El archivo `GoogleService-Info.plist` ya está asociado al target iOS. La app usa notificaciones locales para el seguimiento de cuatro horas en este MVP; una versión posterior puede migrar a FCM y tareas programadas para garantizar recordatorios desde el servidor.

## Alcance actual

Incluye login con Google, chat, aclaraciones y correcciones, registro en Firestore, pendientes mediante gesto hacia arriba, seguimiento de cuatro horas, doble confirmación de “No lo comí”, conteo de calorías consumidas/evitadas y progreso semanal gamificado. Sugerencias saludables según ubicación y Android quedan para la siguiente etapa.
