# Prompt para implementar Antoja2 en Android

Quiero que implementes la versión Android de **Antoja2**, manteniendo el mismo producto, flujo y lenguaje visual que la app iOS existente.

El repositorio público con la implementación de referencia está aquí:

https://github.com/PatrickSpace/Antoja2

Antes de programar, clona o inspecciona completamente el repositorio y trabaja contra el estado más reciente de `main`. Revisa también los commits `329bbff` (progreso semanal gamificado) y `2da25ee` (recordatorio diario de pendientes), porque contienen las funcionalidades más nuevas que deben quedar reflejadas en Android. Usa especialmente estos archivos como fuente de verdad:

- `Antoja2/Views/ChatView.swift`
- `Antoja2/Views/PendingCravingsView.swift`
- `Antoja2/Views/ProgressDashboardView.swift`
- `Antoja2/Views/MainContainerView.swift`
- `Antoja2/Views/Components/ChatBubble.swift`
- `Antoja2/Views/Components/CravingDraftCard.swift`
- `Antoja2/Views/LoginView.swift`
- `Antoja2/Theme/AppTheme.swift`
- `Antoja2/ViewModels/ChatViewModel.swift`
- `Antoja2/ViewModels/ProgressViewModel.swift`
- `Antoja2/Models/CravingModels.swift`
- `Antoja2/Models/ProgressModels.swift`
- `Antoja2/Services/CravingRepository.swift`
- `Antoja2/Services/CravingInterpreter.swift`
- `Antoja2/Services/ProgressRepository.swift`
- `Antoja2/Services/NotificationService.swift`
- `functions/index.js`
- `firestore.rules`

## Objetivo

Construye una app Android nativa con **Kotlin y Jetpack Compose** que replique el frontend y el comportamiento de la versión iOS. No modifiques ni rompas el proyecto iOS ni el backend existente. Coloca el proyecto Android en una carpeta claramente separada, por ejemplo `android/`, dentro del mismo repositorio.

La app es un MVP privado para dos personas. Evita una arquitectura innecesariamente compleja, pero mantén separación clara entre UI, ViewModels, repositorios y modelos.

## Tecnologías

- Kotlin.
- Jetpack Compose y Material 3.
- Una sola Activity.
- Navigation Compose para Chat, Progreso y Configuración.
- ViewModel, StateFlow y coroutines.
- Firebase Authentication con **Google como único proveedor**.
- Cloud Firestore.
- Firebase Functions Callable.
- WorkManager para el recordatorio local después de cuatro horas y para el resumen diario de pendientes.
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
- Menú sencillo con Chat, Progreso y Configuración.
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
- Explicación de que, con 2 o más pendientes, se recuerda diariamente a las 7:00 a. m. desde el día siguiente.
- Estado o solicitud del permiso de notificaciones.
- Botón para cerrar sesión.
- No añadas opciones complejas todavía.

### Progreso semanal gamificado

Replica fielmente `ProgressDashboardView`, `ProgressViewModel`, `ProgressModels` y `ProgressRepository` de iOS. La pantalla debe abrirse desde el menú y desde el botón de gráfico del encabezado del chat.

- Agrupa los antojos en semanas de lunes a domingo usando la zona horaria `America/Lima`.
- Permite navegar entre semanas, sin avanzar más allá de la semana actual ni retroceder antes del primer registro.
- El número principal muestra únicamente la suma de `estimatedAvoidedCalories` de documentos con estado `avoided_confirmed`.
- También muestra el rango acumulado mínimo–máximo, cantidad de evitados, resueltos y pendientes de la semana.
- Incluye un gráfico de barras de las últimas 8 semanas con las calorías evitadas estimadas.
- Incluye una colección visual semanal: una tarjeta por cada antojo confirmado como no comido, con título, porción, rango de calorías y fecha.
- Calcula 10 XP por cada seguimiento resuelto, tanto `consumed` como `avoided_confirmed`; cada nivel requiere 100 XP.
- Replica la racha y las cinco insignias de iOS con exactamente las mismas condiciones de desbloqueo.
- Incluye estados de carga, vacío y error, además de la nota de que las calorías son estimaciones y no equivalen directamente a pérdida de peso.
- No escribas datos nuevos de gamificación en Firestore: deriva progreso, nivel, racha e insignias a partir de los documentos existentes, igual que iOS.

### Recordatorio diario de pendientes a las 7:00 a. m.

Replica la intención de `NotificationService.syncDailyPendingReminders`:

- Cuando la lista sincronizada de Firestore tenga **2 o más** antojos con estado `pending`, programa una notificación local genérica para las **7:00 a. m. del día siguiente**, usando `America/Lima`.
- Mientras sigan existiendo 2 o más pendientes, debe volver a evaluarse diariamente a las 7:00 a. m. y mostrar: título “Tienes decisiones pendientes” y texto “Abre Antoja2 y completa tus antojos pendientes.”
- No incluyas nombres de comidas ni calorías en la notificación para proteger la privacidad.
- Si la cantidad baja a 0 o 1, cancela el trabajo diario único. Cancélalo también al cerrar sesión.
- Usa un `OneTimeWorkRequest` único calculado hasta la siguiente ejecución de las 7:00 a. m. y vuelve a encadenarlo después de ejecutarse si la condición continúa. No uses un intervalo fijo de 24 horas, porque se desplazaría con cambios horarios o retrasos del sistema.
- El Worker debe consultar el estado actual del usuario antes de notificar. Si ya no hay sesión o quedan menos de 2 pendientes, no notifica ni vuelve a programarse.
- Usa un nombre estable de trabajo único y `ExistingWorkPolicy.REPLACE` al cruzar a 2 o más pendientes; evita trabajos duplicados al recibir varios snapshots de Firestore.
- Crea un canal de notificaciones propio, solicita `POST_NOTIFICATIONS` en Android 13+ y conserva el recordatorio individual de cuatro horas en un canal apropiado.
- WorkManager puede entregar unos minutos después de las 7:00 a. m. por las restricciones de batería de Android; no solicites permisos de alarma exacta para este MVP.

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
12. Sincroniza el trabajo diario de las 7:00 a. m. cada vez que cambie la cantidad de pendientes.
13. Actualiza la pantalla Progreso en tiempo real usando el historial compartido de Firestore.

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
- Si la Callable Function devuelve `resource-exhausted` y `details.reason == "openai_credits_exhausted"`, muestra claramente “El servicio de IA se quedó sin créditos. Inténtalo más tarde.”, en lugar de presentarlo como un error de conexión.
- Añade previews de Compose donde ayuden.
- Añade pruebas unitarias del ViewModel, del mapeo de la respuesta estructurada, de los cálculos semanales/XP/insignias y del cálculo de la próxima ejecución a las 7:00 a. m.
- Compila con Gradle y corrige todos los errores antes de terminar.
- Ejecuta lint y pruebas disponibles.
- Documenta en el README de Android cómo registrar la app en Firebase, dónde colocar `google-services.json` y cómo ejecutarla.
- No hagas deploy del backend ni modifiques datos de producción sin autorización.

## Git y entrega final

- Antes de editar, comprueba el estado del repositorio y conserva cualquier cambio ajeno existente.
- No modifiques ni reformatees archivos de iOS salvo que sea estrictamente necesario y se explique.
- Al terminar, revisa el diff, asegúrate de que no haya secretos ni `google-services.json` en Git y agrega únicamente los archivos relacionados con Android.
- Crea un commit descriptivo, por ejemplo `feat(android): add gamified progress and daily pending reminder`.
- Si el remoto y las credenciales están disponibles, haz `push` de la rama de trabajo al repositorio. Nunca uses force push.
- Informa el nombre de la rama, el hash del commit y si el push terminó correctamente. Si no tienes permisos, deja el commit local listo e indica el comando exacto que debe ejecutar el usuario.

Al finalizar, entrega un resumen de los archivos creados, las validaciones ejecutadas, el resultado del push y cualquier paso manual pendiente en Firebase Console.
