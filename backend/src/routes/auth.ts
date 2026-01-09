import express from 'express';
import bcrypt from 'bcrypt';
import { pool } from '../db.js';
import { z } from 'zod';

const router = express.Router();

const signupSchema = z.object({ name: z.string().min(1), email: z.string().email(), password: z.string().min(6) });

router.post('/signup', async (req, res) => {
  const parsed = signupSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Please check your information and try again.' });
  const { name, email, password } = parsed.data;

  const client = await pool.connect();
  try {
    const existing = await client.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rowCount > 0) return res.status(409).json({ error: 'This email is already in use.' });
    const hashed = await bcrypt.hash(password, 10);
    const result = await client.query('INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id', [name, email, hashed]);
    const id = result.rows[0].id;
    // Set session
    (req.session as any).userId = id;
    res.json({ user: { id, name, email } });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(1) });

router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Please check your information and try again.' });
  const { email, password } = parsed.data;
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT id, name, email, password_hash FROM users WHERE email = $1', [email]);
    if (result.rowCount === 0) return res.status(401).json({ error: 'Invalid email or password.' });
    const { id, name, password_hash } = result.rows[0];
    const ok = await bcrypt.compare(password, password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid email or password.' });
    (req.session as any).userId = id;
    res.json({ user: { id, name, email } });
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

router.post('/logout', async (req, res) => {
  req.session?.destroy((err) => {
    if (err) return res.status(500).json({ error: 'Something went wrong. Please try again later.' });
    res.clearCookie('connect.sid');
    res.json({ ok: true });
  });
});

// Delete account and cascade entries
router.delete('/account', async (req, res) => {
  const userId = (req.session as any).userId;
  if (!userId) return res.status(401).json({ error: 'Please log in to continue.' });
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM reflections WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM categories WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM entries WHERE user_id = $1', [userId]);
    await client.query('DELETE FROM users WHERE id = $1', [userId]);
    await client.query('COMMIT');
    req.session?.destroy(() => {});
    res.json({ ok: true });
  } catch (e) {
    await client.query('ROLLBACK');
    // eslint-disable-next-line no-console
    console.error(e);
    res.status(500).json({ error: 'Something went wrong. Please try again later.' });
  } finally {
    client.release();
  }
});

export default router;
