const { Client } = require('pg');

export default async function handler(req, res) {
  // Configuración de CORS básica para peticiones desde el mismo dominio o local
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { sql, parameters } = req.body;
  if (!sql) {
    return res.status(400).json({ error: 'Missing SQL query' });
  }

  // Fallback to manual connection params if DB_URL is not set as a single string
  const connectionString = process.env.DB_URL || `postgres://${process.env.DB_USER}:${process.env.DB_PASS}@ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require`;

  const client = new Client({
    connectionString,
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    // In pg package, parameters are passed as an array [val1, val2] 
    // but our Dart service sends a Map. We need to convert it or use named placeholders.
    // However, for simplicity in this bridge, we expect the parameters to work or we convert them.
    // If parameters is a Map, we transform it:
    let finalParams = parameters;
    let finalSql = sql;

    if (parameters && typeof parameters === 'object' && !Array.isArray(parameters)) {
      // Very simple named parameter replacement for @param -> $1, $2...
      const keys = Object.keys(parameters);
      finalParams = [];
      keys.forEach((key, index) => {
        const regex = new RegExp(`@${key}\\b`, 'g');
        finalSql = finalSql.replace(regex, `$${index + 1}`);
        finalParams.push(parameters[key]);
      });
    }

    const result = await client.query(finalSql, finalParams);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('SERVERLESS_API_ERROR:', error);
    res.status(500).json({ 
      error: error.message,
      hint: 'Verifica los Environment Variables en Vercel y el nombre de tus tablas.',
      requestId: req.headers['x-vercel-id'] || 'no-id'
    });
  } finally {
    try {
      await client.end();
    } catch (e) {
      // Ignore end errors
    }
  }
}
