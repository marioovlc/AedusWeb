/**
 * api/ai.js — Proxy serverless para llamadas a la IA de Groq.
 *
 * El cliente envía el prompt aquí. Este handler llama a Groq
 * usando el API key que solo existe en las variables de entorno del servidor.
 * Nunca se expone GROQ_API_KEY al cliente.
 */

const ALLOWED_MODELS = [
  'llama-3.3-70b-versatile',
  'llama-3.1-8b-instant',
  'mixtral-8x7b-32768',
];

export default async function handler(req, res) {
  // ── CORS ──────────────────────────────────────────────────────────────────
  const allowedOrigin = process.env.ALLOWED_ORIGIN || '*';
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
  res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'Content-Type, X-API-KEY',
  );
  res.setHeader('X-Content-Type-Options', 'nosniff');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // ── Autenticación: INTERNAL_API_KEY ───────────────────────────────────────
  const internalKey = process.env.INTERNAL_API_KEY;
  if (!internalKey) {
    console.error('SERVER MISCONFIGURATION: INTERNAL_API_KEY not set');
    return res.status(500).json({ error: 'Server misconfiguration' });
  }
  if (req.headers['x-api-key'] !== internalKey) {
    return res.status(403).json({ error: 'Forbidden: Invalid API Key' });
  }

  // ── Validar variables de entorno del servidor ─────────────────────────────
  const groqApiKey = process.env.AI_API_KEY || process.env.GROQ_API_KEY;
  const groqApiUrl = process.env.AI_API_URL || process.env.GROQ_API_URL || 'https://api.groq.com/openai/v1/chat/completions';
  const defaultModel = process.env.AI_MODEL || process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';

  if (!groqApiKey) {
    console.error('SERVER MISCONFIGURATION: AI_API_KEY not set');
    return res.status(500).json({ error: 'AI service not configured' });
  }

  // ── Validar body ──────────────────────────────────────────────────────────
  const { messages, model, temperature } = req.body || {};

  if (!messages || !Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: 'Missing or invalid messages array' });
  }

  const safeModel = ALLOWED_MODELS.includes(model) ? model : defaultModel;
  const safeTemp = typeof temperature === 'number' ? Math.min(Math.max(temperature, 0), 1) : 0.3;

  // ── Llamada a Groq (server-side) ──────────────────────────────────────────
  try {
    const groqResponse = await fetch(groqApiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: safeModel,
        messages,
        temperature: safeTemp,
      }),
    });

    const data = await groqResponse.json();

    if (!groqResponse.ok) {
      console.error('Groq API error:', groqResponse.status, data);
      return res.status(groqResponse.status).json({
        error: data?.error?.message || 'AI service error',
      });
    }

    return res.status(200).json(data);
  } catch (err) {
    console.error('AI proxy error:', err);
    return res.status(500).json({ error: 'Failed to reach AI service' });
  }
}
