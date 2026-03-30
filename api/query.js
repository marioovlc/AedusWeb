const { Client } = require('pg');

export default async function handler(req, res) {
  // Configuración de CORS
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

  // RECUPERACIÓN DE VARIABLES
  const rawUrl = (process.env.DB_URL || '').trim();
  const dbUser = (process.env.DB_USER || '').trim();
  const dbPass = (process.env.DB_PASS || '').trim();
  const dbSchema = (process.env.DB_SCHEMA || 'public').trim();

  let finalConnectionString = '';

  if (rawUrl.startsWith('jdbc:postgresql://')) {
    const hostPart = rawUrl.split('//')[1].split('/')[0].split('?')[0];
    const dbPart = rawUrl.split('//')[1].split('/')[1]?.split('?')[0] || 'neondb';
    finalConnectionString = `postgres://${dbUser}:${dbPass}@${hostPart}/${dbPart}?sslmode=require`;
  } else if (rawUrl.startsWith('postgres://')) {
    if (!rawUrl.includes(':') || !rawUrl.includes('@')) {
       const hostPart = rawUrl.replace('postgres://', '').split('/')[0];
       const dbPart = rawUrl.split('/').pop()?.split('?')[0] || 'neondb';
       finalConnectionString = `postgres://${dbUser}:${dbPass}@${hostPart}/${dbPart}?sslmode=require`;
    } else {
      finalConnectionString = rawUrl;
    }
  } else if (dbUser && dbPass) {
    finalConnectionString = `postgres://${dbUser}:${dbPass}@ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require`;
  }

  const client = new Client({
    connectionString: finalConnectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    
    // Opcional: configurar el search_path basado en la variable de entorno
    if (dbSchema) {
      await client.query(`SET search_path TO ${dbSchema}`);
    }
    
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
    console.error('SERVERLESS_API_ERROR:', error);
    
    // DIAGNÓSTICO DE ESQUEMAS SI LA TABLA NO EXISTE
    let extraInfo = {};
    if (error.code === '42P01') {
      try {
        const tables = await client.query("SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') LIMIT 20");
        extraInfo.available_tables = tables.rows;
      } catch (e) {}
    }

    res.status(500).json({ 
      error: error.message,
      code: error.code,
      hint: "La tabla no existe en el esquema especificado.",
      ...extraInfo
    });
  } finally {
    try { await client.end(); } catch (e) {}
  }
}
