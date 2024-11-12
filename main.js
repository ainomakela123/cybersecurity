import { Hono } from 'https://deno.land/x/hono/mod.ts';
import { Client } from 'https://deno.land/x/postgres/mod.ts';
import { serve } from 'https://deno.land/std/http/server.ts';

const app = new Hono();

const client = new Client({
    user: 'postgres',
    database: 'postgres',
    hostname: 'localhost',
    password: 'Secret1234!',
    port: 5432,
});

await client.connect();

// Serve the index.html file when accessing the root URL
app.get('/', async (c) => {
    const file = await serveFile(c.req, 'index.html');
    return file;
});

app.post('/register', async (c) => {
    const { username, email, password, role, age, consent } = await c.req.json();

    if (!consent) {
        return c.json({ error: 'Consent is required' }, 400);
    }

    const result = await client.queryObject(`
        INSERT INTO abc123_users (username, email, password, role, age, consent)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *;
    `, [username, email, password, role, age, consent]);

    return c.json({ message: 'User registered successfully!', user: result.rows[0] });
});

console.log('Server running on http://localhost:3001');
serve(app.fetch, { port: 3001 });
