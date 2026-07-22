import { GoogleGenerativeAI } from '@google/generative-ai';

const AI_TUTOR_SYSTEM_PROMPT = `
You are an expert school teacher.

Rules:
- Explain concepts in simple language.
- Give step-by-step explanations.
- Be friendly and encouraging.
- Suitable for school students.
- If the answer involves math, show steps.
- Avoid unnecessary complexity.
`;

const GEMINI_PRIMARY_MODEL = 'gemini-2.5-flash';
const GEMINI_FALLBACK_MODEL = 'gemini-2.0-flash';
const GEMINI_TIMEOUT_MS = 20_000;
const RETRYABLE_STATUS_CODES = new Set([429, 500, 502, 503, 504]);
const RETRY_DELAYS_MS = [1_000, 2_000, 4_000];
const AI_TUTOR_BUSY_MESSAGE =
  'Our AI tutor is currently busy helping other students. Please try again in a few moments.';

function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

function getGeminiStatusCode(error) {
  const statusCode = error.statusCode || error.status;
  if (statusCode) {
    return Number(statusCode);
  }

  const statusCodeMatch = error.message?.match(/\b(429|500|502|503|504)\b/);
  return statusCodeMatch ? Number(statusCodeMatch[1]) : undefined;
}

function isRetryableGeminiError(error) {
  const statusCode = getGeminiStatusCode(error);
  return RETRYABLE_STATUS_CODES.has(statusCode);
}

function generateWithTimeout(model, question) {
  let timeoutId;
  const timeout = new Promise((_, reject) => {
    timeoutId = setTimeout(() => {
      const error = new Error('Gemini request timed out after 20 seconds');
      error.statusCode = 504;
      reject(error);
    }, GEMINI_TIMEOUT_MS);
  });

  return Promise.race([model.generateContent(question), timeout]).finally(() => {
    clearTimeout(timeoutId);
  });
}

async function generateWithRetries({ genAI, modelName, question, role }) {
  const model = genAI.getGenerativeModel({
    model: modelName,
    systemInstruction: AI_TUTOR_SYSTEM_PROMPT,
  });

  let retryCount = 0;
  const modelStartedAt = Date.now();

  // eslint-disable-next-line no-console
  console.log('Gemini request started', {
    role,
    model: modelName,
    questionLength: question.length,
    at: new Date().toISOString(),
  });

  for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt += 1) {
    const attemptStartedAt = Date.now();

    try {
      const result = await generateWithTimeout(model, question);
      const answer = result.response.text().trim();

      if (!answer) {
        const error = new Error('Gemini returned an empty answer');
        error.statusCode = 502;
        throw error;
      }

      // eslint-disable-next-line no-console
      console.log('Gemini request completed', {
        role,
        model: modelName,
        retryCount,
        answerLength: answer.length,
        attemptResponseTimeMs: Date.now() - attemptStartedAt,
        responseTimeMs: Date.now() - modelStartedAt,
        at: new Date().toISOString(),
      });

      return {
        answer,
        retryCount,
      };
    } catch (error) {
      const statusCode = getGeminiStatusCode(error);
      const shouldRetry =
        isRetryableGeminiError(error) && attempt < RETRY_DELAYS_MS.length;

      if (!shouldRetry) {
        error.statusCode = statusCode || error.statusCode || 502;

        // eslint-disable-next-line no-console
        console.error('Gemini request failed', {
          role,
          model: modelName,
          retryCount,
          statusCode: error.statusCode,
          message: error.message,
          at: new Date().toISOString(),
        });

        throw error;
      }

      const delayMs = RETRY_DELAYS_MS[attempt];
      retryCount += 1;

      // eslint-disable-next-line no-console
      console.warn('Gemini retry scheduled', {
        role,
        model: modelName,
        retryCount,
        statusCode,
        delayMs,
        message: error.message,
        at: new Date().toISOString(),
      });

      await wait(delayMs);
    }
  }

  const error = new Error(AI_TUTOR_BUSY_MESSAGE);
  error.statusCode = 429;
  throw error;
}

export async function askAiTutor(question) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    const error = new Error('GEMINI_API_KEY is not configured');
    error.statusCode = 500;
    throw error;
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const requestStartedAt = Date.now();

  try {
    const { answer } = await generateWithRetries({
      genAI,
      modelName: GEMINI_PRIMARY_MODEL,
      question,
      role: 'primary',
    });

    // eslint-disable-next-line no-console
    console.log('AI Tutor Gemini request finished', {
      primaryModel: GEMINI_PRIMARY_MODEL,
      fallbackUsed: false,
      responseTimeMs: Date.now() - requestStartedAt,
      at: new Date().toISOString(),
    });

    return answer;
  } catch (primaryError) {
    // eslint-disable-next-line no-console
    console.warn('Gemini fallback activated', {
      primaryModel: GEMINI_PRIMARY_MODEL,
      fallbackModel: GEMINI_FALLBACK_MODEL,
      primaryStatusCode: primaryError.statusCode,
      primaryMessage: primaryError.message,
      at: new Date().toISOString(),
    });

    try {
      const { answer } = await generateWithRetries({
        genAI,
        modelName: GEMINI_FALLBACK_MODEL,
        question,
        role: 'fallback',
      });

      // eslint-disable-next-line no-console
      console.log('AI Tutor Gemini request finished', {
        primaryModel: GEMINI_PRIMARY_MODEL,
        fallbackModel: GEMINI_FALLBACK_MODEL,
        fallbackUsed: true,
        responseTimeMs: Date.now() - requestStartedAt,
        at: new Date().toISOString(),
      });

      return answer;
    } catch (fallbackError) {
      // eslint-disable-next-line no-console
      console.error('AI Tutor Gemini request exhausted', {
        primaryModel: GEMINI_PRIMARY_MODEL,
        fallbackModel: GEMINI_FALLBACK_MODEL,
        fallbackUsed: true,
        finalStatusCode: fallbackError.statusCode,
        finalMessage: fallbackError.message,
        responseTimeMs: Date.now() - requestStartedAt,
        at: new Date().toISOString(),
      });

      const error = new Error(AI_TUTOR_BUSY_MESSAGE);
      error.statusCode = 429;
      throw error;
    }
  }
}
