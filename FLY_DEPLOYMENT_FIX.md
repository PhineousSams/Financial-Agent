# Fly.io Deployment Fix Guide

## Problem
Getting `mix esbuild default --minify` error during `fly launch` with exit code 1.

## Root Cause
The error occurs because:
1. Node.js was not installed in the Docker build environment
2. npm dependencies were not properly installed before asset compilation
3. esbuild dependency was missing from package.json

## Solution Applied

### 1. Updated Dockerfile
- ✅ **Added Node.js 18.x installation**
- ✅ **Added npm dependency installation step**
- ✅ **Fixed asset compilation order**

### 2. Updated package.json
- ✅ **Added esbuild dependency**
- ✅ **Added build scripts for Tailwind CSS**
- ✅ **Cleaned up unused dependencies**

### 3. Fixed Asset Pipeline
- ✅ **Proper npm install before asset compilation**
- ✅ **Correct build order in Dockerfile**

## Files Modified

### Dockerfile Changes
```dockerfile
# Added Node.js installation
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Added npm dependency installation
RUN cd assets && npm install --only=production
```

### package.json Changes
```json
{
  "scripts": {
    "build": "tailwindcss --input=css/app.css --output=../priv/static/assets/app.css --minify",
    "deploy": "tailwindcss --input=css/app.css --output=../priv/static/assets/app.css --minify"
  },
  "dependencies": {
    "@fortawesome/fontawesome-svg-core": "^6.6.0",
    "@fortawesome/free-brands-svg-icons": "^6.6.0",
    "@fortawesome/free-regular-svg-icons": "^6.6.0",
    "@fortawesome/free-solid-svg-icons": "^6.6.0",
    "alpinejs": "^3.14.1",
    "esbuild": "^0.19.0"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.10"
  }
}
```

## Next Steps

### 1. Clean Previous Build Artifacts
```bash
# Remove any cached build files
rm -rf _build
rm -rf deps
rm -rf assets/node_modules
```

### 2. Test Local Build (Optional)
```bash
# Test the asset compilation locally
cd assets
npm install
cd ..
MIX_ENV=prod mix assets.deploy
```

### 3. Deploy to Fly.io
```bash
# Now try the deployment again
fly launch
```

## If You Still Get Errors

### Check Node.js Version
```bash
# In your Dockerfile, verify Node.js is installed
docker build -t test-build .
docker run -it test-build node --version
```

### Alternative: Use Pre-built Assets
If the build still fails, you can pre-build assets locally:

```bash
# Build assets locally
cd assets && npm install && npm run build
cd .. && MIX_ENV=prod mix phx.digest

# Then modify Dockerfile to skip asset building
# Comment out the npm install and mix assets.deploy lines
```

### Debug Build Process
```bash
# Run fly deploy with verbose output
fly deploy --verbose

# Check build logs
fly logs
```

## Environment Variables for Fly.io

After successful deployment, set your environment variables:

```bash
# Required secrets
fly secrets set SECRET_KEY_BASE="$(mix phx.gen.secret)"
fly secrets set DATABASE_URL="your-database-url"
fly secrets set OPENAI_API_KEY="your-openai-key"

# OAuth credentials
fly secrets set GOOGLE_CLIENT_ID="your-google-client-id"
fly secrets set GOOGLE_CLIENT_SECRET="your-google-client-secret"
fly secrets set HUBSPOT_CLIENT_ID="your-hubspot-client-id"
fly secrets set HUBSPOT_CLIENT_SECRET="your-hubspot-client-secret"

# Optional but recommended
fly secrets set LIVE_VIEW_SIGNING_SALT="$(mix phx.gen.secret)"
fly secrets set SESSION_SIGNING_SALT="$(mix phx.gen.secret)"
fly secrets set GUARDIAN_SECRET_KEY="$(mix phx.gen.secret)"
```

## Verification

After deployment:

1. **Check app status**: `fly status`
2. **View logs**: `fly logs`
3. **Test the app**: Visit your app URL
4. **Check database**: `fly ssh console` then test DB connection

## Common Issues and Solutions

### Issue: "npm: command not found"
**Solution**: Node.js installation failed. Check Dockerfile Node.js installation step.

### Issue: "esbuild: command not found"
**Solution**: esbuild dependency missing. Check package.json includes esbuild.

### Issue: "Permission denied" errors
**Solution**: Check file permissions in Dockerfile, ensure proper user setup.

### Issue: "Module not found" errors
**Solution**: npm dependencies not installed properly. Check npm install step.

## Success Indicators

✅ **Build completes without errors**
✅ **Assets are compiled successfully**
✅ **App starts without crashes**
✅ **Database connections work**
✅ **OAuth integrations function**

Your Financial Agent application should now deploy successfully to Fly.io!
