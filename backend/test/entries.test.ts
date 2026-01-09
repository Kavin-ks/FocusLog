import request from 'supertest';
import app from '../src/index';

describe('Entries', () => {
  let cookie: string;
  const username = `u${Date.now()}`;
  const password = 'password123';

  beforeAll(async () => {
    const signup = await request(app).post('/api/auth/signup').send({ username, password });
    cookie = signup.headers['set-cookie']?.[0];
  });

  it('creates, updates, deletes an entry', async () => {
    const create = await request(app).post('/api/entries').set('Cookie', cookie).send({
      start_time: new Date().toISOString(),
      end_time: new Date(Date.now() + 1000 * 60 * 30).toISOString(),
      activity_name: 'Test',
      category: 'work',
    });
    expect(create.statusCode).toBe(200);
    const id = create.body.entry.id;

    const update = await request(app).put(`/api/entries/${id}`).set('Cookie', cookie).send({
      start_time: create.body.entry.start_time,
      end_time: create.body.entry.end_time,
      activity_name: 'Test 2',
      category: 'work',
    });
    expect(update.statusCode).toBe(200);
    expect(update.body.entry.activity_name).toBe('Test 2');

    const del = await request(app).delete(`/api/entries/${id}`).set('Cookie', cookie);
    expect(del.statusCode).toBe(200);
  });

  it('exports JSON', async () => {
    const resp = await request(app).get('/api/entries/export/json').set('Cookie', cookie);
    expect(resp.statusCode).toBe(200);
    expect(resp.body).toHaveProperty('entries');
  });
});