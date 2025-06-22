# Fly.io Setup Commands

Now that your database is created, follow these commands to complete the deployment:

## 1. Set Required Environment Variables

```bash
# Generate and set secrets
fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
fly secrets set LIVE_VIEW_SIGNING_SALT="$(mix phx.gen.secret)"
fly secrets set SESSION_SIGNING_SALT="$(mix phx.gen.secret)"
fly secrets set GUARDIAN_SECRET_KEY="$(mix phx.gen.secret)"

# Set your OpenAI API key (required for AI features)
fly secrets set OPENAI_API_KEY="your-openai-api-key-here"

# Set OAuth credentials (required for integrations)
fly secrets set GOOGLE_CLIENT_ID="your-google-client-id"
fly secrets set GOOGLE_CLIENT_SECRET="your-google-client-secret"
fly secrets set HUBSPOT_CLIENT_ID="your-hubspot-client-id"
fly secrets set HUBSPOT_CLIENT_SECRET="your-hubspot-client-secret"

# Optional: Set your domain
fly secrets set PHX_HOST="your-app-name.fly.dev"
```

## 2. Deploy the Application

```bash
# Deploy with the updated configuration
fly deploy
```

## 3. Check Deployment Status

```bash
# Check if the app is running
fly status

# View logs to ensure everything is working
fly logs

# Open your application
fly open
```

## 4. Verify Database Connection

```bash
# Connect to your app to check database
fly ssh console

# Inside the console, test the database connection
/app/bin/financial_agent eval "FinancialAgent.Repo.query!(\"SELECT 1\")"
```

## 5. If You Need to Run Migrations Manually

```bash
# If migrations didn't run automatically
fly ssh console
/app/bin/financial_agent eval "FinancialAgent.Release.migrate()"
```

## Environment Variables You'll Need

### Required:
- `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
- `DATABASE_URL` - Automatically set by Fly.io
- `OPENAI_API_KEY` - Your OpenAI API key for AI features

### OAuth Integrations:
- `GOOGLE_CLIENT_ID` & `GOOGLE_CLIENT_SECRET` - For Gmail/Calendar
- `HUBSPOT_CLIENT_ID` & `HUBSPOT_CLIENT_SECRET` - For CRM integration

### Optional but Recommended:
- `LIVE_VIEW_SIGNING_SALT` - For LiveView security
- `SESSION_SIGNING_SALT` - For session security
- `GUARDIAN_SECRET_KEY` - For JWT authentication
- `PHX_HOST` - Your domain name

## Troubleshooting

### If deployment fails:
1. Check logs: `fly logs`
2. Verify secrets are set: `fly secrets list`
3. Check app status: `fly status`

### If database connection fails:
1. Verify DATABASE_URL is set: `fly secrets list`
2. Check if database is running: `fly pg status`
3. Try connecting manually: `fly pg connect`

### If assets don't load:
1. Verify the build completed successfully
2. Check if static files are present in the container
3. Ensure the asset pipeline ran during build

## Success Indicators

✅ **App status shows "running"**
✅ **No errors in logs**
✅ **Can access the app via browser**
✅ **Database queries work**
