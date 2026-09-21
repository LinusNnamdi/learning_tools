import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

setGlobalOptions({
  region: "africa-south1",
  maxInstances: 10,
});

const jobSearchApiKey = defineSecret("JOB_SEARCH_API_KEY");

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
      message: "Secure Firebase backend is working.",
    };
  },
);