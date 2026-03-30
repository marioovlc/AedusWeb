const { Client } = require('pg');

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { sql, parameters } = req.body;

  const client = new Client({
    connectionString: process.env.DB_URL || `postgres://${process.env.DB_USER}:${process.env.DB_PASS}@ep-mute-frog-agiqzzew-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require`,
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    await client.connect();
    const result = await client.query(sql, parameters);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Database Error:', error);
    res.status(500).json({ error: error.message });
  } finally {
    await client.end();
  }
}
