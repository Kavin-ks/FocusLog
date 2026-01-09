import request from 'supertest';
import app from '../src/index';

describe('Auth', () => {
  it('signup and login flow', async () => {
    // Note: these tests expect a running test DB configured with DATABASE_URL
    const username = `u${Date.now()}`;
    const password = 'password123';

    const signup = await request(app).post('/api/auth/signup').send({ username, password });
    expect(signup.statusCode).toBe(200);
    expect(signup.body.user).toBeDefined();

    // Logout first
    await request(app).post('/api/auth/logout');

    const login = await request(app).post('/api/auth/login').send({ username, password });
    expect(login.statusCode).toBe(200);
    expect(login.body.user).toBeDefined();
  });
});
