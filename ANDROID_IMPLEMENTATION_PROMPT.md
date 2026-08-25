# Prompt para implementar Antoja2 en Android

Quiero que implementes la versión Android de **Antoja2**, manteniendo el mismo producto, flujo y lenguaje visual que la app iOS existente.

El repositorio público con la implementación de referencia está aquí:

https://github.com/PatrickSpace/Antoja2

Antes de programar, clona o inspecciona completamente el repositorio. Usa especialmente estos archivos como fuente de verdad:

- `Antoja2/Views/ChatView.swift`
- `Antoja2/Views/PendingCravingsView.swift`
- `Antoja2/Views/Components/ChatBubble.swift`
- `Antoja2/Views/Components/CravingDraftCard.swift`
- `Antoja2/Views/LoginView.swift`
- `Antoja2/Theme/AppTheme.swift`
- `Antoja2/ViewModels/ChatViewModel.swift`
- `Antoja2/Models/CravingModels.swift`
- `Antoja2/Services/CravingRepository.swift`
- `Antoja2/Services/CravingInterpreter.swift`
- `functions/index.js`
- `firestore.rules`

## Objetivo

Construye una app Android nativa con **Kotlin y Jetpack Compose** que replique el frontend y el comportamiento de la versión iOS. No modifiques ni rompas el proyecto iOS ni el backend existente. Coloca el proyecto Android en una carpeta claramente separada, por ejemplo `android/`, dentro del mismo repositorio.

La app es un MVP privado para dos personas. Evita una arquitectura innecesariamente compleja, pero mantén separación clara entre UI, ViewModels, repositorios y modelos.

## Tecnologías

- Kotlin.
- Jetpack Compose y Material 3.
- Una sola Activity.
- Navigation Compose para Chat y Configuración.
- ViewModel, StateFlow y coroutines.
- Firebase Authentication con **Google como único proveedor**.
- Cloud Firestore.
- Firebase Functions Callable.
- WorkManager para el recordatorio local después de cuatro horas.
- Credential Manager para el login moderno con Google.
- Usa Firebase BoM y versiones estables actuales compatibles entre sí.

El `applicationId` sugerido es `boxell.antoja2`, salvo que exista una configuración Android diferente en Firebase. No inventes `google-services.json`: explica que debe descargarse del proyecto Firebase `antoja2-271ed` después de registrar la app Android y colócalo en la ruta estándar únicamente cuando el archivo real esté disponible.

## Seguridad

- No pongas nunca `OPENAI_API_KEY` en Android, Gradle, `local.properties` ni recursos.
- Android debe llamar a la Callable Function existente `interpretCraving` en la región `southamerica-west1`.
- La Function ya usa OpenAI desde el servidor y devuelve datos estructurados.
- Conserva las reglas por usuario bajo `users/{uid}`.
- Añade al `.gitignore` los archivos locales, secretos y artefactos de Android, pero no elimines las reglas existentes del repositorio.

## Experiencia visual

Replica el diseño de iOS, no una interfaz Material genérica:

- Nombre visible: **Antoja2**.
- Tema claro fijo para mantener contraste consistente.
- Fondo crema cálido: aproximadamente `#F6F4EC`.
- Coral principal: aproximadamente `#E85733`.
- Coral suave: aproximadamente `#FFDBC0`.
- Texto principal casi negro con tono oliva: aproximadamente `#1F211C`.
- Texto secundario: aproximadamente `#636657`.
- Verde de éxito: aproximadamente `#338F61`.
- Tarjetas blancas con bordes muy suaves, esquinas grandes y sombras discretas.
- Tipografía legible, cálida y redondeada cuando sea posible.
- Reutiliza como referencia los iconos de `Antoja2/Assets.xcassets/AppIcon.appiconset/` y crea un adaptive icon Android coherente.
- Todo texto sobre fondos claros debe ser oscuro. Los placeholders del chat también deben tener contraste explícito.

## Pantallas y navegación

### Login

- Fondo crema con decoración coral suave.
- Icono de marca y título “Antoja2”.
- Descripción breve.
- Un único botón “Continuar con Google”.
- Estado de carga y mensaje de error.

### Chat principal

Esta debe ser siempre la primera pantalla después del login.

- Encabezado con menú hamburguesa, nombre Antoja2, saludo y contador de pendientes.
- Menú sencillo con únicamente Chat y Configuración.
- Conversación en burbujas tipo ChatGPT.
- Mensajes del usuario alineados a la derecha y respuestas a la izquierda.
- Campo de texto grande, multilinea, claro, con placeholder oscuro y botón coral de enviar.
- Indicador “Entendiendo tu antojo…” mientras se procesa.
- La corrección de porciones y supuestos ocurre escribiendo en este mismo chat; no crees formularios separados.

### Resumen previo al registro

Cuando la IA tiene información suficiente, muestra dentro de la burbuja:

- Nombre estructurado de la comida.
- Porción entendida.
- Rango estimado de calorías.
- Todos los supuestos usados: porción, tamaño, preparación, piel, acompañamientos, salsas, bebida y marca cuando correspondan.
- Razón de cada supuesto.
- Botón “Cambiar”, que solicita la corrección mediante el chat.
- Botón “Registrar”.

No guardes el antojo hasta que el usuario pulse Registrar. Si falta una porción crítica, presenta la pregunta devuelta por la IA en el chat y procesa la respuesta contra el borrador anterior.

### Pendientes

- Añade un asa visible encima del compositor del chat.
- Un gesto hacia arriba o tocar el asa abre un `ModalBottomSheet` con los antojos pendientes.
- Cada tarjeta muestra título, porción, rango calórico y hora del seguimiento.
- Incluye exactamente dos acciones: “Lo comí” y “No lo comí”.
- “No lo comí” siempre abre una segunda confirmación explícita preguntando si no consumió ni siquiera una parte.
- “Lo comí” no necesita esa segunda confirmación.
- Mantén fondo claro y texto oscuro en toda la hoja.

### Configuración

- Información básica de la cuenta Google.
- Explicación de que el seguimiento ocurre después de cuatro horas.
- Estado o solicitud del permiso de notificaciones.
- Botón para cerrar sesión.
- No añadas opciones complejas todavía.

## Flujo funcional

1. El usuario escribe algo como “Quiero comer un cuarto de pollo a la brasa”.
2. Android llama a `interpretCraving` enviando `message` y, si existe, `previousDraft`.
3. La respuesta se convierte a los mismos modelos que iOS: `CravingDraft`, `CravingAssumption`, `Craving` y `CravingStatus`.
4. Si `needsClarification` es `true`, muestra `clarifyingQuestion` en el chat.
5. Si está completo, muestra el resumen y los supuestos antes de guardar.
6. Al confirmar, crea un documento en `users/{uid}/cravings/{id}` con estado `pending`, `createdAt`, `followUpDueAt`, rango de calorías y supuestos.
7. Programa un WorkManager para dentro de cuatro horas con una notificación genérica y privada.
8. El antojo permanece pendiente hasta que se resuelva.
9. Si se marca “Lo comí”, cambia el estado a `consumed` y guarda el punto medio del rango en `estimatedConsumedCalories`.
10. Si se confirma “No lo comí”, cambia el estado a `avoided_confirmed` y guarda el punto medio en `estimatedAvoidedCalories`.
11. Después de resolverlo, muestra en el chat un mensaje claro y sin culpa con las calorías consumidas o un mensaje motivador con las calorías evitadas.

## Contrato de datos

No inventes un contrato diferente. Inspecciona `functions/index.js`, `CravingModels.swift` y `CravingRepository.swift`. Respeta exactamente los nombres de campos y valores de estado existentes para que iOS y Android compartan la misma cuenta y los mismos documentos de Firestore.

La Function requiere un usuario autenticado y devuelve, como mínimo:

- `title`
- `normalizedFoodName`
- `portionText`
- `estimatedCaloriesMin`
- `estimatedCaloriesMax`
- `assumptions`
- `needsClarification`
- `clarifyingQuestion`
- `confidence`
- `source`

## Calidad y validación

- Implementa el proyecto, no entregues únicamente una arquitectura o fragmentos.
- Incluye estados de carga, errores, sesión restaurada y listas vacías.
- Añade previews de Compose donde ayuden.
- Añade pruebas unitarias del ViewModel o del mapeo de la respuesta estructurada.
- Compila con Gradle y corrige todos los errores antes de terminar.
- Ejecuta lint y pruebas disponibles.
- Documenta en el README de Android cómo registrar la app en Firebase, dónde colocar `google-services.json` y cómo ejecutarla.
- No hagas deploy del backend ni modifiques datos de producción sin autorización.

Al finalizar, entrega un resumen de los archivos creados, las validaciones ejecutadas y cualquier paso manual pendiente en Firebase Console.
