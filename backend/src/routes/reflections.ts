import express from 'express';
import { pool } from '../db.js';

const router = express.Router();

function requireAuth(req: any, res: any, next: any) {
  if (!req.session || !req.session.userId) return res.status(401).json({ error: 'Please log in to continue.' });
  next();
}

router.use(requireAuth);

// List reflections for current user
router.get('/', async (req, res) => {
  const userId = req.session.userId;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM reflections WHERE user_id = $1 ORDER BY date DESC', [userId]);
    res.json({ reflections: result.rows });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

// Create a new reflection
router.post('/', async (req, res) => {
  const userId = req.session.userId;
  const { date, content } = req.body;
  if (!date || !content || typeof content !== 'string' || content.trim().length === 0) {
    return res.status(400).json({ error: 'Please provide a valid date and content.' });
  }
  const client = await pool.connect();
  try {
    const result = await client.query(
      'INSERT INTO reflections (user_id, date, content) VALUES ($1, $2, $3) RETURNING *',
      [userId, date, content.trim()],
    );
    res.json({ reflection: result.rows[0] });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

// Update a reflection (must belong to user)
router.put('/:id', async (req, res) => {
  const userId = req.session.userId;
  const id = Number(req.params.id);
  const { date, content } = req.body;
  if (!date || !content || typeof content !== 'string' || content.trim().length === 0) {
    return res.status(400).json({ error: 'Please provide a valid date and content.' });
  }
  const client = await pool.connect();
  try {
    // Ensure ownership
    const found = await client.query('SELECT user_id FROM reflections WHERE id = $1', [id]);
    if (found.rowCount === 0) return res.status(404).json({ error: 'Reflection not found.' });
    if (found.rows[0].user_id !== userId) return res.status(403).json({ error: 'Access denied.' });

    const result = await client.query(
      'UPDATE reflections SET date = $1, content = $2 WHERE id = $3 RETURNING *',
      [date, content.trim(), id],
    );
    res.json({ reflection: result.rows[0] });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

// Delete a reflection (must belong to user)
router.delete('/:id', async (req, res) => {
  const userId = req.session.userId;
  const id = Number(req.params.id);
  const client = await pool.connect();
  try {
    const found = await client.query('SELECT user_id FROM reflections WHERE id = $1', [id]);
    if (found.rowCount === 0) return res.status(404).json({ error: 'Reflection not found.' });
    if (found.rows[0].user_id !== userId) return res.status(403).json({ error: 'Access denied.' });

    await client.query('DELETE FROM reflections WHERE id = $1', [id]);
    res.json({ ok: true });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

export default router;