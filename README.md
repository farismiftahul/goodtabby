# Tabbycat — Debate Tournament Tabulation

Tabbycat is a debate tournament tabulation system for two-team parliamentary formats. It supports features like automated draw generation, adjudicator allocation, real-time ballot entry, and live participant feedback.

- **Original Project**: [TabbycatDebate/tabbycat](https://github.com/TabbycatDebate/tabbycat)
- **Documentation**: [tabbycat.readthedocs.io](https://tabbycat.readthedocs.io/)

---

## Deploy to Render

This guide walks you through deploying Tabbycat on [Render](https://render.com) with a [Supabase](https://supabase.com) PostgreSQL database.

### Prerequisites

- A [Render](https://dashboard.render.com/register) account
- A [Supabase](https://supabase.com) account with a project created
- This repository pushed to GitHub/GitLab

---

### Step 1: Get Your Supabase Database URL

1. Go to your **Supabase Dashboard** → select your project
2. Navigate to **Settings** → **Database**
3. Under **Connection string**, select **URI** and copy the **Transaction** pooler string (port `6543`)

It will look like this:

```
postgresql://postgres.[your-ref]:[your-password]@aws-0-[region].pooler.supabase.com:6543/postgres
```

> **Note:** If your password contains special characters (like `#`, `@`, `%`), they must be URL-encoded in the connection string. For example, `#` becomes `%23`.

---

### Step 2: Create a Render Web Service

1. Go to [Render Dashboard](https://dashboard.render.com) → **New** → **Web Service**
2. Connect your GitHub/GitLab repository
3. Configure the service with these settings:

| Setting | Value |
|---------|-------|
| **Name** | `tabbycat` (or your preferred name) |
| **Runtime** | **Python** |
| **Build Command** | `./bin/render-compile.sh` |
| **Start Command** | `npm run render-serve` |

> ⚠️ **Important:** Make sure the Runtime is set to **Python**, not Docker. The repository contains a Dockerfile for local development, but Render should use the native Python runtime.

---

### Step 3: Set Environment Variables

In the Render Dashboard, go to your service → **Environment** → add the following variables:

#### Required Variables

| Key | Value | Description |
|-----|-------|-------------|
| `ON_RENDER` | `true` | Activates Render-specific Django settings |
| `DJANGO_SECRET_KEY` | *(click Generate or use a random string)* | Cryptographic signing key for Django |
| `DATABASE_URL` | `postgresql://postgres.[ref]:[pass]@...pooler.supabase.com:6543/postgres` | Your Supabase connection string from Step 1 |

#### Optional Variables

| Key | Value | Description |
|-----|-------|-------------|
| `TAB_DIRECTOR_EMAIL` | `your@email.com` | Tournament director contact email |
| `TIME_ZONE` | `Asia/Dhaka` | IANA timezone for the tournament ([list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)) |
| `DISABLE_SENTRY` | `1` | Set to `1` to disable error tracking to Sentry |
| `SENDGRID_API_KEY` | *(your key)* | For email notifications via SendGrid |
| `DEFAULT_FROM_EMAIL` | `noreply@yourdomain.com` | Sender address for emails |

> ⚠️ **Notice for Free Tier Users:** Render's free web services block all outbound traffic to SMTP ports (25, 587, 465). If you are using the free tier, email notifications via `EMAIL_HOST` or `SENDGRID_API_KEY` (using SMTP) will not work. You must upgrade to a paid Render plan to send emails. See [Render's Changelog](https://render.com/changelog/free-web-services-will-no-longer-allow-outbound-traffic-to-smtp-ports) for details.

---

### Step 4: Deploy

1. Click **Manual Deploy** → **Clear build cache & deploy**
2. Wait for the build to complete (first build takes ~5-10 minutes)
3. Once you see `Build successful 🎉`, wait for the deploy step
4. Your app will be live at `https://your-service-name.onrender.com`

---

### Step 5: Create an Admin Account

After deployment, you'll need to create a superuser to access the admin panel:

1. Go to your service in the Render Dashboard
2. Click **Shell** (in the sidebar)
3. Run:

```bash
cd tabbycat
python manage.py createsuperuser
```

4. Follow the prompts to set up your admin username, email, and password
5. Access the admin panel at `https://your-service-name.onrender.com/admin/`

---

### Optional: Add Redis (for Real-Time Features)

Tabbycat uses Redis for WebSocket channels (live updates) and caching. Without Redis, the app falls back to in-memory alternatives (works fine for small tournaments).

To add Redis:

1. Go to Render Dashboard → **New** → **Redis**
2. Create a Redis instance (name it `tabbycat-redis`)
3. Add these environment variables to your web service:

| Key | Value |
|-----|-------|
| `REDIS_HOST` | *(internal host from your Redis instance)* |
| `REDIS_PORT` | *(port from your Redis instance)* |

---

## Troubleshooting

### Build fails with `No such file: local.py`

The `ON_RENDER` environment variable is not set. Add `ON_RENDER = true` in your Render service's Environment settings.

### `Application exited early` or port timeout

- Make sure the Runtime is set to **Python** (not Docker)
- Check that the Start Command is `npm run render-serve`

### Database connection errors

- Verify your `DATABASE_URL` is correct and uses the **Transaction pooler** (port `6543`) from Supabase
- Make sure special characters in the password are URL-encoded (`#` → `%23`, `@` → `%40`)

### `SPLIT_SETTINGS: imported docker.py` in logs

Render is using Docker instead of Python runtime. Go to Settings → change Runtime to **Python**.

---

## Local Development

For local development, see the [Tabbycat documentation](https://tabbycat.readthedocs.io/en/stable/install/local.html).

### Quick Start (Docker)

```bash
docker-compose up
```

### Quick Start (Manual)

```bash
# Install Python dependencies
pip install pipenv
pipenv install

# Install Node.js dependencies
npm install

# Build frontend
npm run build

# Run the development server
cd tabbycat
python manage.py migrate
python manage.py createsuperuser
npm run serve  # from project root
```

---

## License

Tabbycat is licensed under the [GNU Affero General Public License v3.0](LICENSE.md).
