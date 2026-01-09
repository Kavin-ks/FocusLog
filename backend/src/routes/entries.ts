import express from 'express';
import { pool } from '../db.js';

const router = express.Router();

function requireAuth(req: any, res: any, next: any) {
  if (!req.session || !req.session.userId) return res.status(401).json({ error: 'unauthenticated' });
  next();
}

router.use(requireAuth);

// List entries for current user
router.get('/', async (req, res) => {
  const userId = req.session.userId;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM entries WHERE user_id = $1 ORDER BY start_time', [userId]);
    res.json({ entries: result.rows });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});

// Create a new entry
router.post('/', async (req, res) => {
  const userId = req.session.userId;
  const { start_time, end_time, activity_name, category, energy, intent } = req.body;
  const client = await pool.connect();
  try {
    const result = await client.query(
      `INSERT INTO entries (user_id, start_time, end_time, activity_name, category, energy, intent)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [userId, start_time, end_time, activity_name, category, energy || null, intent || null],
    );
    res.json({ entry: result.rows[0] });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});

// Update an entry (must belong to user)
router.put('/:id', async (req, res) => {
  const userId = req.session.userId;
  const id = Number(req.params.id);
  const { start_time, end_time, activity_name, category, energy, intent } = req.body;
  const client = await pool.connect();
  try {
    // Ensure ownership
    const found = await client.query('SELECT user_id FROM entries WHERE id = $1', [id]);
    if (found.rowCount === 0) return res.status(404).json({ error: 'not_found' });
    if (found.rows[0].user_id !== userId) return res.status(403).json({ error: 'forbidden' });

    const result = await client.query(
      `UPDATE entries SET start_time=$1, end_time=$2, activity_name=$3, category=$4, energy=$5, intent=$6 WHERE id=$7 RETURNING *`,
      [start_time, end_time, activity_name, category, energy || null, intent || null, id],
    );
    res.json({ entry: result.rows[0] });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});

// Delete an entry (must belong to user)
router.delete('/:id', async (req, res) => {
  const userId = req.session.userId;
  const id = Number(req.params.id);
  const client = await pool.connect();
  try {
    const found = await client.query('SELECT user_id FROM entries WHERE id = $1', [id]);
    if (found.rowCount === 0) return res.status(404).json({ error: 'not_found' });
    if (found.rows[0].user_id !== userId) return res.status(403).json({ error: 'forbidden' });

    await client.query('DELETE FROM entries WHERE id = $1', [id]);
    res.json({ ok: true });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});

// Export user data (JSON)
router.get('/export/json', async (req, res) => {
  const userId = req.session.userId;
  const client = await pool.connect();
  try {
    const entries = (await client.query('SELECT * FROM entries WHERE user_id = $1 ORDER BY start_time', [userId])).rows;
    // reflections not yet implemented, but include placeholder
    res.json({ entries });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'internal' });
  } finally {
    client.release();
  }
});

export default router;
