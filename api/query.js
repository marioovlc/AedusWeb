const { Client } = require('pg');
const bcrypt = require('bcryptjs');

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

  const { sql, parameters, action } = req.body;
  if (!sql && action !== 'login') return res.status(400).json({ error: 'Missing SQL query' });

  // RECUPERACIÓN DE VARIABLES CON LIMPIEZA
  const rawUrl = (process.env.DB_URL || '').trim();
  const dbUser = (process.env.DB_USER || '').trim();
  const dbPass = (process.env.DB_PASS || '').trim();

  let finalConnectionString = '';

  // CASO A: Tenemos una URL de JDBC (frecuente en Neon/Java)
  if (rawUrl.startsWith('jdbc:postgresql://')) {
    const hostPart = rawUrl.split('//')[1].split('/')[0].split('?')[0];
    const dbPart = rawUrl.split('//')[1].split('/')[1]?.split('?')[0] || 'neondb';
    if (dbUser && dbPass) {
      finalConnectionString = `postgres://${dbUser}:${dbPass}@${hostPart}/${dbPart}?sslmode=require`;
    } else {
      finalConnectionString = rawUrl.replace('jdbc:postgresql://', 'postgres://');
    }
  } 
  else if (rawUrl.startsWith('postgres://')) {
    if (!rawUrl.includes(':') || !rawUrl.includes('@')) {
       const hostPart = rawUrl.replace('postgres://', '').split('/')[0];
       const dbPart = rawUrl.split('/').pop()?.split('?')[0] || 'neondb';
       finalConnectionString = `postgres://${dbUser}:${dbPass}@${hostPart}/${dbPart}?sslmode=require`;
    } else {
      finalConnectionString = rawUrl;
    }
  } 
  else if (dbUser && dbPass) {
    finalConnectionString = `postgres://${dbUser}:${dbPass}@ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require`;
  }

  if (!finalConnectionString) {
    return res.status(500).json({ error: "Configuración de conexión incompleta en Vercel." });
  }

  const client = new Client({
    connectionString: finalConnectionString,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    
    // MODO ESPECIAL: LOGIN SEGURO
    if (action === 'login') {
      const email = parameters.email;
      const pass = parameters.password;
      
      const userRes = await client.query("SELECT * FROM neon_auth.user WHERE email = $1", [email]);
      if (userRes.rows.length === 0) {
        return res.status(401).json({ error: 'Usuario no encontrado' });
      }
      
      const user = userRes.rows[0];
      const match = await bcrypt.compare(pass, user.password);
      
      if (!match) {
        return res.status(401).json({ error: 'Contraseña incorrecta' });
      }
      
      // No devolvemos el hash del password por seguridad
      delete user.password;
      return res.status(200).json([user]); // Devolvemos array para compatibilidad con query
    }

    // MODO NORMAL: QUERY SQL
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
    res.status(500).json({ 
      error: error.message,
      hint: "Check DB connection details."
    });
  } finally {
    try { await client.end(); } catch (e) {}
  }
}
