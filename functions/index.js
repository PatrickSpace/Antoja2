const {initializeApp} = require("firebase-admin/app");
const {defineSecret} = require("firebase-functions/params");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");

initializeApp();

const openAIAPIKey = defineSecret("OPENAI_API_KEY");

const cravingSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "title",
    "normalizedFoodName",
    "portionText",
    "estimatedCaloriesMin",
    "estimatedCaloriesMax",
    "assumptions",
    "needsClarification",
    "clarifyingQuestion",
    "confidence",
  ],
  properties: {
    title: {
      type: "string",
      description: "Nombre corto y natural de la comida en español.",
    },
    normalizedFoodName: {
      type: "string",
      description: "Nombre canónico sin marcas de cantidad.",
    },
    portionText: {
      type: "string",
      description: "Porción entendida. Vacío si falta una porción crítica.",
    },
    estimatedCaloriesMin: {
      type: "integer",
      description: "Límite inferior estimado. Cero si falta aclaración.",
    },
    estimatedCaloriesMax: {
      type: "integer",
      description: "Límite superior estimado. Cero si falta aclaración.",
    },
    assumptions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["id", "label", "value", "reason", "editable"],
        properties: {
          id: {type: "string"},
          label: {type: "string"},
          value: {type: "string"},
          reason: {type: "string"},
          editable: {type: "boolean"},
        },
      },
    },
    needsClarification: {type: "boolean"},
    clarifyingQuestion: {type: "string"},
    confidence: {
      type: "string",
      enum: ["low", "medium", "high"],
    },
  },
};

exports.interpretCraving = onCall(
    {
      region: "southamerica-west1",
      secrets: [openAIAPIKey],
      timeoutSeconds: 30,
      memory: "256MiB",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
      }

      const message = typeof request.data?.message === "string" ?
        request.data.message.trim() : "";
      if (!message || message.length > 1000) {
        throw new HttpsError(
            "invalid-argument",
            "Describe el antojo en un mensaje de hasta 1000 caracteres.",
        );
      }

      const previousDraft = request.data?.previousDraft ?? null;
      const input = previousDraft ?
        [
          "Borrador anterior:",
          JSON.stringify(previousDraft),
          "Corrección o respuesta del usuario:",
          message,
        ].join("\n") :
        `Nuevo antojo del usuario: ${message}`;

      const response = await fetch("https://api.openai.com/v1/responses", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${openAIAPIKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-5.6-luna",
          store: false,
          instructions: [
            "Eres el intérprete nutricional de una app personal de antojos en Perú.",
            "Convierte el mensaje en un borrador, no en un registro definitivo.",
            "Expón TODOS los supuestos que afecten las calorías: porción, tamaño, preparación, piel, acompañamientos, salsas, bebida y marca.",
            "No agregues acompañamientos que el usuario no haya mencionado; indícalos como excluidos cuando sean una ambigüedad habitual.",
            "Si falta la porción o la diferencia posible es grande, pregunta una sola cosa concreta y marca needsClarification=true.",
            "Si necesitas aclaración, usa cero para ambas calorías.",
            "Si hay datos suficientes, estima un rango razonable, evita falsa precisión y explica cada supuesto en español claro.",
            "Cuando recibas un borrador anterior, aplica la corrección del usuario y devuelve el borrador completo actualizado.",
            "No diagnostiques, no moralices la comida y no afirmes que la estimación es exacta.",
          ].join(" "),
          input,
          text: {
            format: {
              type: "json_schema",
              name: "craving_analysis",
              strict: true,
              schema: cravingSchema,
            },
          },
        }),
      });

      if (!response.ok) {
        const responseText = await response.text();
        logger.error("OpenAI response failed", {
          status: response.status,
          body: responseText.slice(0, 500),
        });
        throw new HttpsError(
            "unavailable",
            "No pudimos interpretar el antojo en este momento.",
        );
      }

      const responseData = await response.json();
      const outputText = findOutputText(responseData.output);
      if (!outputText) {
        logger.error("OpenAI response had no output text", {
          responseId: responseData.id,
        });
        throw new HttpsError("internal", "La respuesta de la IA está incompleta.");
      }

      try {
        return {
          ...JSON.parse(outputText),
          source: "ai_estimate",
        };
      } catch (error) {
        logger.error("Could not parse structured OpenAI output", {error});
        throw new HttpsError("internal", "No pudimos leer la estimación.");
      }
    },
);

function findOutputText(output) {
  if (!Array.isArray(output)) return null;

  for (const item of output) {
    if (!Array.isArray(item.content)) continue;
    for (const content of item.content) {
      if (content.type === "output_text" && typeof content.text === "string") {
        return content.text;
      }
    }
  }
  return null;
}
