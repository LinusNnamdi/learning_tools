import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

// -----------------------------------------------------------------------------
// Global configuration
// -----------------------------------------------------------------------------
// These settings apply to all 2nd-generation Firebase Functions
// defined in this file unless a function overrides them individually.
setGlobalOptions({
  region: "africa-south1",
  maxInstances: 10,
});

// -----------------------------------------------------------------------------
// Secrets
// -----------------------------------------------------------------------------
// JOB_SEARCH_API_KEY is stored in Google Cloud Secret Manager.
// The actual secret value is NOT stored in this source code.
const jobSearchApiKey = defineSecret("JOB_SEARCH_API_KEY");

// -----------------------------------------------------------------------------
// Secure callable function
// -----------------------------------------------------------------------------
export const secureBackendTest = onCall(
  {
    // Makes JOB_SEARCH_API_KEY available only to this function.
    secrets: [jobSearchApiKey],

    // Rejects requests that don't contain a valid Firebase App Check token.
    enforceAppCheck: true,
  },
  async () => {
    // Read the secret securely at runtime.
    const apiKey = jobSearchApiKey.value();

    // Safety check.
    if (!apiKey) {
      throw new HttpsError(
        "internal",
        "Backend secret is unavailable.",
      );
    }

    // IMPORTANT:
    // Never return apiKey to the Flutter application.
    // Later, we will use apiKey here on the server to call
    // the external Job Search API.

    return {
      success: true,
      message: "Secure Firebase backend is working.",
    };
  },
);