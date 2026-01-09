import express from 'express';
import { pool } from '../db.js';

const router = express.Router();

function requireAuth(req: any, res: any, next: any) {
  if (!req.session || !req.session.userId) return res.status(401).json({ error: 'Please log in to continue.' });
  next();
}

router.use(requireAuth);

// List categories for current user
router.get('/', async (req, res) => {
  const userId = req.session.userId;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM categories WHERE user_id = $1 ORDER BY name', [userId]);
    res.json({ categories: result.rows });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

// Create a new category
router.post('/', async (req, res) => {
  const userId = req.session.userId;
  const { name } = req.body;
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({ error: 'Please provide a valid category name.' });
  }
  const client = await pool.connect();
  try {
    const result = await client.query(
      'INSERT INTO categories (user_id, name) VALUES ($1, $2) RETURNING *',
      [userId, name.trim()],
    );
    res.json({ category: result.rows[0] });
  } catch (e) {
    if (e.code === '23505') { // unique violation
      return res.status(409).json({ error: 'This category name already exists.' });
    }
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

// Update a category (must belong to user)
router.put('/:id', async (req, res) => {
  const userId = req.session.userId;
  const id = Number(req.params.id);
  const { name } = req.body;
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({ error: 'Please provide a valid category name.' });
  }
  const client = await pool.connect();
  try {
    // Ensure ownership
    const found = await client.query('SELECT user_id FROM categories WHERE id = $1', [id]);
    if (found.rowCount === 0) return res.status(404).json({ error: 'Category not found.' });
    if (found.rows[0].user_id !== userId) return res.status(403).json({ error: 'Access denied.' });

    const result = await client.query(
      'UPDATE categories SET name = $1 WHERE id = $2 RETURNING *',
      [name.trim(), id],
    );
    res.json({ category: result.rows[0] });
  } catch (e) {
    if (e.code === '23505') { // unique violation
      return res.status(409).json({ error: 'This category name already exists.' });
    }
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

// Delete a category (must belong to user)
router.delete('/:id', async (req, res) => {
  const userId = req.session.userId;
  const id = Number(req.params.id);
  const client = await pool.connect();
  try {
    const found = await client.query('SELECT user_id FROM categories WHERE id = $1', [id]);
    if (found.rowCount === 0) return res.status(404).json({ error: 'Category not found.' });
    if (found.rows[0].user_id !== userId) return res.status(403).json({ error: 'Access denied.' });

    await client.query('DELETE FROM categories WHERE id = $1', [id]);
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