/**
 * api/upload.js — Proxy serverless para subidas a Cloudinary.
 *
 * El cliente envía el archivo (base64) aquí. Este handler genera la firma
 * SHA1 con el API secret y llama a Cloudinary desde el servidor.
 * Nunca se expone CLOUDINARY_API_SECRET al cliente.
 */

import crypto from 'crypto';

/**
 * Genera la firma SHA1 requerida por Cloudinary.
 * @param {Record<string, string>} params - Parámetros a firmar (ordenados).
 * @param {string} apiSecret - API secret de Cloudinary.
 */
function generateSignature(params, apiSecret) {
  const sortedKeys = Object.keys(params).sort();
  const queryString = sortedKeys.map((k) => `${k}=${params[k]}`).join('&');
  return crypto
    .createHash('sha1')
    .update(`${queryString}${apiSecret}`)
    .digest('hex');
}

export default async function handler(req, res) {
  // ── CORS ──────────────────────────────────────────────────────────────────
  const allowedOrigin = process.env.ALLOWED_ORIGIN || '*';
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
  res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-API-KEY');
  res.setHeader('X-Content-Type-Options', 'nosniff');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const internalKey = process.env.INTERNAL_API_KEY;
  if (!internalKey || internalKey.trim() === '') {
    console.error('SERVER MISCONFIGURATION: INTERNAL_API_KEY no configurado en entorno.');
    return res.status(500).json({ error: 'Server misconfiguration' });
  }
  if (req.headers['x-api-key'] !== internalKey) {
    return res.status(403).json({ error: 'Forbidden: Invalid API Key' });
  }

  // ── Validar variables de entorno del servidor ─────────────────────────────
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    console.error('SERVER MISCONFIGURATION: CLOUDINARY_* vars not set');
    return res.status(500).json({ error: 'Storage service not configured' });
  }

  // ── Validar body ──────────────────────────────────────────────────────────
  // El cliente envía: { fileBase64: "...", fileName: "...", isAudio: bool }
  const { fileBase64, fileName, isAudio } = req.body || {};

  if (!fileBase64 || !fileName) {
    return res.status(400).json({ error: 'Missing fileBase64 or fileName' });
  }

  const resourceType = isAudio ? 'video' : 'image';
  const timestamp = Math.floor(Date.now() / 1000).toString();

  const signParams = { timestamp };
  if (isAudio) signParams['resource_type'] = 'video';

  const signature = generateSignature(signParams, apiSecret);

  // ── Construir multipart y subir a Cloudinary ──────────────────────────────
  try {
    const fileBuffer = Buffer.from(fileBase64, 'base64');
    const blob = new Blob([fileBuffer]);

    const form = new FormData();
    form.append('api_key', apiKey);
    form.append('timestamp', timestamp);
    form.append('signature', signature);
    if (isAudio) form.append('resource_type', 'video');
    form.append('file', blob, fileName);

    const cloudinaryUrl = `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`;

    const cloudRes = await fetch(cloudinaryUrl, {
      method: 'POST',
      body: form,
      // Al usar el FormData nativo, NO enviamos headers manuales.
      // fetch generará automáticamente el Content-Type con el boundary correcto.
    });

    const data = await cloudRes.json();

    if (!cloudRes.ok) {
      console.error('Cloudinary upload error:', cloudRes.status, data);
      return res.status(cloudRes.status).json({
        error: 'Upload failed',
      });
    }

    return res.status(200).json({ url: data.secure_url });
  } catch (err) {
    console.error('Upload proxy error:', err);
    return res.status(500).json({ error: 'Failed to upload file' });
  }
}
