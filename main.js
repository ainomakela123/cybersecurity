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

app.get('/', async (c) => {
    try {
        const file = await Deno.readFile('index.html');
        return new Response(file, {
            headers: {
                'content-type': 'text/html',
            },
        });
    } catch (error) {
        console.error('Virhe:', error);
        return c.json({ error: 'Internal Server Error' }, { status: 500 });
    }
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

console.log('Server running on http://localhost:8000');
serve(app.fetch, { port: 8000 });

