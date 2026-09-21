import { setGlobalOptions } from "firebase-functions/v2";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

setGlobalOptions({
  region: "africa-south1",
  maxInstances: 10,
});

const jobSearchApiKey = defineSecret("JOB_SEARCH_API_KEY");

// -----------------------------------------------------------------------------
// 1. Security test
// -----------------------------------------------------------------------------

export const secureBackendTest = onCall(
  {
    secrets: [jobSearchApiKey],
    enforceAppCheck: true,
  },
  async () => {
    const apiKey = jobSearchApiKey.value();

    if (!apiKey) {
      throw new HttpsError(
        "internal",
        "Backend secret is unavailable.",
      );
    }

    return {
      success: true,
      message: "App Check and Secret Manager are working.",
    };
  },
);

// -----------------------------------------------------------------------------
// 2. Gemini bridge for Job Finder
// -----------------------------------------------------------------------------

export const searchJobsWithGemini = onCall(
  {
    secrets: [jobSearchApiKey],
    enforceAppCheck: true,
    timeoutSeconds: 120,
    memory: "256MiB",
  },
  async (request) => {
    const apiKey = jobSearchApiKey.value();

    if (!apiKey) {
      throw new HttpsError(
        "internal",
        "Backend secret is unavailable.",
      );
    }

    // Flutter owns the prompt.
    const prompt = request.data?.prompt;

    if (typeof prompt !== "string" || prompt.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "A non-empty prompt is required.",
      );
    }

    // Prevent accidentally sending an enormous request.
    if (prompt.length > 20000) {
      throw new HttpsError(
        "invalid-argument",
        "The prompt is too large.",
      );
    }

    // -------------------------------------------------
    // Model + retry settings
    // -------------------------------------------------
    const model = "gemini-3.6-flash";   // ← current model (required for new users)
    const maxAttempts = 4;

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/` +
      `${model}:generateContent`;

    let lastStatus = 0;
    let lastBody = "";

    try {
      for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        const response = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": apiKey,
          },
          body: JSON.stringify({
            contents: [
              {
                role: "user",
                parts: [
                  {
                    text: prompt.trim(),
                  },
                ],
              },
            ],
            generationConfig: {
              temperature: 0.2,
              responseMimeType: "application/json",
            },
          }),
        });

        const responseBody = await response.text();
        lastStatus = response.status;
        lastBody = responseBody;

        // ---------- SUCCESS ----------
        if (response.ok) {
          let geminiResponse: any;

          try {
            geminiResponse = JSON.parse(responseBody);
          } catch (error) {
            console.error(
              "Unable to parse Gemini HTTP response:",
              error,
            );
            throw new HttpsError(
              "internal",
              "Gemini returned an invalid API response.",
            );
          }

          const parts =
            geminiResponse?.candidates?.[0]?.content?.parts;

          if (!Array.isArray(parts) || parts.length === 0) {
            console.error(
              "Gemini returned no usable content.",
              JSON.stringify(geminiResponse),
            );
            throw new HttpsError(
              "internal",
              "Gemini returned no usable content.",
            );
          }

          const text = parts
            .map((part: any) => {
              return typeof part?.text === "string"
                ? part.text
                : "";
            })
            .join("")
            .trim();

          if (!text) {
            throw new HttpsError(
              "internal",
              "Gemini returned an empty response.",
            );
          }

          // IMPORTANT:
          // Do NOT JSON.parse Gemini's generated text here.
          // Flutter will clean / extract / validate it.
          return {
            success: true,
            rawText: text,
          };
        }

        // ---------- RETRYABLE ERRORS ----------
        const isRetryable =
          response.status === 503 ||
          response.status === 429 ||
          response.status === 500 ||
          response.status === 502 ||
          response.status === 504;

        if (!isRetryable || attempt === maxAttempts) {
          // Final failure – give a clear message
          console.error("Gemini API request failed:", {
            status: response.status,
            body: responseBody,
            model,
            attempt,
          });

          let clientMessage = `Gemini error (${response.status})`;
          try {
            const errJson = JSON.parse(responseBody);
            const googleMsg = errJson?.error?.message;
            if (googleMsg) {
              clientMessage = `Gemini error (${response.status}): ${googleMsg}`;
            }
          } catch (_) {
            // keep the short message
          }

          throw new HttpsError("internal", clientMessage);
        }

        // Exponential backoff + small random jitter
        // attempt 1 → ~1s, 2 → ~2s, 3 → ~4s
        const delayMs =
          Math.min(1000 * Math.pow(2, attempt - 1), 8000) +
          Math.floor(Math.random() * 400);

        console.warn(
          `Gemini ${response.status} – retry ${attempt}/${maxAttempts} in ${delayMs}ms`,
        );

        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }

      // Should never reach here, but just in case
      throw new HttpsError(
        "internal",
        `Gemini error (${lastStatus}): ${lastBody || "Unknown error"}`,
      );
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      console.error("Unexpected Gemini error:", error);

      throw new HttpsError(
        "internal",
        "Unable to complete the Gemini request.",
      );
    }
  },
);