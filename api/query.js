const { Client } = require('pg');

export default async function handler(req, res) {
  // CORS configuration
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

  // 1. Get credentials from environment
  let connectionString = process.env.DB_URL;
  const user = process.env.DB_USER;
  const password = process.env.DB_PASS;

  if (connectionString && connectionString.startsWith('jdbc:')) {
    connectionString = connectionString.replace('jdbc:postgresql://', 'postgres://');
  }

  // 2. Configure Client
  // Explicitly passing user and password because they might be missing from the connectionString
  const clientConfig = {
    connectionString,
    user: user,
    password: password,
    ssl: { rejectUnauthorized: false }
  };

  // If connectionString is still empty, let's try to build it or just use the separate parts
  if (!connectionString && user && password) {
    clientConfig.host = 'ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech';
    clientConfig.database = 'neondb';
  }

  const client = new Client(clientConfig);

  try {
    await client.connect();
    
    // Transform named parameters (@param -> $1)
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
      hint: "Asegúrate de que DB_PASS sea un string válido en Vercel.",
      debug: {
        has_url: !!process.env.DB_URL,
        has_user: !!process.env.DB_USER,
        has_pass: !!process.env.DB_PASS,
        pass_type: typeof process.env.DB_PASS
      }
    });
  } finally {
    try { await client.end(); } catch (e) {}
  }
}
