const { Client } = require('pg');
const bcrypt = require('bcryptjs');

// ACTION MAP - Sentencias SQL seguras predefinidas
const ACTION_MAP = {
  init_db: `
    CREATE SCHEMA IF NOT EXISTS gestion_incidencias;
  `,
  // Se excluye la contraseña para no fugar datos sensibles
  get_users: `SELECT id, name, email, rol, status, aedu_coins FROM neon_auth.user ORDER BY name ASC`,
  get_incidencias: `SELECT i.*, e.nombre as estado_nombre FROM gestion_incidencias.incidencias i JOIN gestion_incidencias.estados e ON i.estado_id = e.id ORDER BY i.fecha DESC`,
  get_kpis: `SELECT e.nombre as estado, count(*) as count FROM gestion_incidencias.incidencias i JOIN gestion_incidencias.estados e ON i.estado_id = e.id GROUP BY e.nombre`,
  get_contactos: `SELECT id, name, email, rol, status, aedu_coins FROM neon_auth.user WHERE id != @id`,
  get_aulas: `SELECT * FROM gestion_incidencias.aulas ORDER BY nombre ASC`,
  get_mensajes: `SELECT * FROM gestion_incidencias.mensajes WHERE (usuario_id = @me AND receptor_id = @other) OR (usuario_id = @other AND receptor_id = @me) ORDER BY fecha ASC`,
  create_incidencia: `INSERT INTO gestion_incidencias.incidencias (titulo, descripcion, usuario_id, aula_id, categoria_id, estado_id, fecha, imagen_url) VALUES (@titulo, @descripcion, @uId, @aId, @cId, 5, NOW(), @img) RETURNING *`,
  send_message: `INSERT INTO gestion_incidencias.mensajes (usuario_id, receptor_id, texto, imagen_url, audio_url, fecha, leido) VALUES (@me, @other, @txt, @img, @aud, NOW(), false) RETURNING *`,
  request_user: `INSERT INTO neon_auth.user (name, email, password, rol, status, aedu_coins) VALUES (@nom, @em, @pass, 'USER', 'INACTIVO', 0) RETURNING *`,
  approve_user: `UPDATE neon_auth.user SET status = 'ACTIVO' WHERE id = @id RETURNING *`,
  reject_user: `DELETE FROM neon_auth.user WHERE id = @id RETURNING *`
};

export default async function handler(req, res) {
  // Configuración de Seguridad y CORS Restringido
  const allowedOrigin = process.env.ALLOWED_ORIGIN || '*'; // En prod debería ser aedus-web.vercel.app
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, X-API-KEY'
  );
  // Security Headers
  res.setHeader('Content-Security-Policy', "default-src 'self'");
  res.setHeader('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-Content-Type-Options', 'nosniff');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  // VALIDACIÓN DE API KEY (PROTECCIÓN CONTRA ACCESO PÚBLICO)
  const apiKey = req.headers['x-api-key'];
  const expectedApiKey = process.env.INTERNAL_API_KEY;
  
  if (!expectedApiKey) {
    console.error('SERVER MISCONFIGURATION: INTERNAL_API_KEY is not set');
    return res.status(500).json({ error: 'Server misconfiguration' });
  }
  
  if (apiKey !== expectedApiKey) {
    return res.status(403).json({ error: 'Forbidden: Invalid API Key' });
  }

  const { parameters, action } = req.body;
  if (!action) return res.status(400).json({ error: 'Missing action' });

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
    
    // MODO LOGIN
    if (action === 'login') {
      const email = parameters?.email;
      const pass = parameters?.password;
      
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
      return res.status(200).json([user]); // Devolvemos array para compatibilidad
    }

    // ACCIONES PREDEFINIDAS DEL MAPA
    if (!ACTION_MAP[action]) {
      return res.status(400).json({ error: 'Invalid action' });
    }

    // INTERCEPT: Encriptar automática y de forma segura peticiones de usuario.
    if (action === 'request_user' && parameters && parameters.pass) {
      parameters.pass = await bcrypt.hash(parameters.pass, 10);
    }

    let baseSql = ACTION_MAP[action];
    let finalParams = [];
    let finalSql = baseSql;

    if (parameters && typeof parameters === 'object' && !Array.isArray(parameters)) {
      const keys = Object.keys(parameters);
      keys.forEach((key, index) => {
        const regex = new RegExp(`@${key}\\b`, 'g');
        finalSql = finalSql.replace(regex, `$${index + 1}`);
        finalParams.push(parameters[key]);
      });
    }

    const result = await client.query(finalSql, finalParams);
    res.status(200).json(result.rows || []);
  } catch (error) {
    console.error('SERVERLESS_API_ERROR:', error);
    res.status(500).json({ 
      error: 'Hubo un error al ejecutar la acción.',
      // hint: solo en dev
      ...(process.env.NODE_ENV !== 'production' && { details: error.message })
    });
  } finally {
    try { await client.end(); } catch (e) {}
  }
}

