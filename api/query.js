const { Client } = require('pg');

export default async function handler(req, res) {
  // Configuración de CORS básica
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { sql, parameters } = req.body;
  if (!sql) return res.status(400).json({ error: 'Missing SQL query' });

  // RECUPERACIÓN Y LIMPIEZA DE LA URL DE CONEXIÓN
  let connectionString = process.env.DB_URL;
  
  if (connectionString) {
    // Si la URL viene en formato JDBC (común en Java), la convertimos al estándar de Postgres
    if (connectionString.startsWith('jdbc:')) {
      connectionString = connectionString.replace('jdbc:postgresql://', 'postgres://');
    }
  } else {
    // Si no hay DB_URL, intentamos construirla con los otros parámetros
    const user = process.env.DB_USER;
    const pass = process.env.DB_PASS;
    if (user && pass) {
      connectionString = `postgres://${user}:${pass}@ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require`;
    }
  }

  if (!connectionString) {
    return res.status(500).json({ 
      error: "No se encontró DB_URL ni credenciales válidas en Vercel.",
      hint: "Asegúrate de que DB_URL (estándar o JDBC) esté en la configuración de Vercel."
    });
  }

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    
    // Transformación de parámetros nombrados (@param -> $1)
    let finalParams = [];
    let finalSql = sql;
    if (parameters && typeof parameters === 'object' && !Array.isArray(parameters)) {
      const keys = Object.keys(parameters);
      keys.forEach((key, index) => {
        const regex = new RegExp(`@${key}\\b`, 'g');
        finalSql = finalSql.replace(regex, `$${index + 1}`);
        finalParams.push(parameters[key]);
      });
    } else {
      finalParams = parameters || [];
    }

    const result = await client.query(finalSql, finalParams);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('API_BRIDGE_ERROR:', error);
    res.status(500).json({ 
      error: error.message,
      code: error.code,
      hint: "Si el error es ECONNREFUSED, revisa que DB_URL sea correcta.",
      jdbc_detected: process.env.DB_URL?.startsWith('jdbc:'),
      env_keys_present: Object.keys(process.env).filter(k => k.includes('DB_'))
    });
  } finally {
    try { await client.end(); } catch (e) {}
  }
}
