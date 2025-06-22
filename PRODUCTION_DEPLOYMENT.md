# Financial Agent - Production Deployment Guide

This guide will help you deploy your Financial Agent application to production with proper configuration and security.

## Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+ database
- Domain name with SSL certificate
- Environment variables configured

## Quick Start

1. **Generate Secrets**
   ```bash
   # Generate required secrets
   mix phx.gen.secret  # Use for SECRET_KEY_BASE
   mix phx.gen.secret  # Use for LIVE_VIEW_SIGNING_SALT
   mix phx.gen.secret  # Use for SESSION_SIGNING_SALT
   mix phx.gen.secret  # Use for GUARDIAN_SECRET_KEY
   ```

2. **Set Environment Variables**
   ```bash
   # Copy the example file and fill in your values
   cp .env.production.example .env.production
   # Edit .env.production with your actual values
   ```

3. **Database Setup**
   ```bash
   # Create and migrate database
   MIX_ENV=prod mix ecto.create
   MIX_ENV=prod mix ecto.migrate
   ```

4. **Build Assets**
   ```bash
   # Install and build frontend assets
   cd assets && npm install && npm run build
   cd .. && MIX_ENV=prod mix phx.digest
   ```

5. **Build Release**
   ```bash
   # Create production release
   MIX_ENV=prod mix release
   ```

## Configuration Details

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Phoenix secret key | Generated with `mix phx.gen.secret` |
| `DATABASE_URL` | PostgreSQL connection string | `ecto://user:pass@host:5432/db` |
| `PHX_HOST` | Your domain name | `your-app.com` |
| `OPENAI_API_KEY` | OpenAI API key for AI features | `sk-...` |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | For Gmail/Calendar integration |
| `HUBSPOT_CLIENT_ID` | HubSpot OAuth client ID | For CRM integration |

### Optional but Recommended

| Variable | Description | Default |
|----------|-------------|---------|
| `POOL_SIZE` | Database connection pool size | `10` |
| `LOG_LEVEL` | Logging level | `info` |
| `SENTRY_DSN` | Error tracking with Sentry | None |
| `REDIS_URL` | Redis for caching/rate limiting | None |

## Deployment Options

### Option 1: Fly.io Deployment

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Login and Initialize**
   ```bash
   fly auth login
   fly launch
   ```

3. **Set Secrets**
   ```bash
   fly secrets set SECRET_KEY_BASE="your-secret-here"
   fly secrets set DATABASE_URL="your-db-url"
   fly secrets set OPENAI_API_KEY="your-openai-key"
   # ... set other secrets
   ```

4. **Deploy**
   ```bash
   fly deploy
   ```

### Option 2: Docker Deployment

1. **Build Docker Image**
   ```bash
   docker build -t financial-agent .
   ```

2. **Run with Environment File**
   ```bash
   docker run -d \
     --name financial-agent \
     --env-file .env.production \
     -p 4000:4000 \
     financial-agent
   ```

### Option 3: Traditional Server Deployment

1. **Install Dependencies**
   ```bash
   # On Ubuntu/Debian
   sudo apt update
   sudo apt install postgresql nginx certbot
   ```

2. **Setup Database**
   ```bash
   sudo -u postgres createuser financial_agent
   sudo -u postgres createdb financial_agent_prod -O financial_agent
   ```

3. **Configure Nginx**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;
       return 301 https://$server_name$request_uri;
   }

   server {
       listen 443 ssl http2;
       server_name your-domain.com;

       ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

       location / {
           proxy_pass http://localhost:4000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

4. **Setup SSL Certificate**
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

5. **Create Systemd Service**
   ```bash
   # Create /etc/systemd/system/financial-agent.service
   [Unit]
   Description=Financial Agent
   After=network.target

   [Service]
   Type=exec
   User=financial_agent
   Group=financial_agent
   WorkingDirectory=/opt/financial_agent
   ExecStart=/opt/financial_agent/bin/financial_agent start
   ExecStop=/opt/financial_agent/bin/financial_agent stop
   Restart=on-failure
   RestartSec=5
   Environment=PHX_SERVER=true
   EnvironmentFile=/opt/financial_agent/.env.production

   [Install]
   WantedBy=multi-user.target
   ```

6. **Start Service**
   ```bash
   sudo systemctl enable financial-agent
   sudo systemctl start financial-agent
   ```

## Security Checklist

- [ ] SSL/TLS enabled with valid certificate
- [ ] Strong, unique secrets generated
- [ ] Database connections encrypted
- [ ] Environment variables secured
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Security headers enabled
- [ ] Regular security updates scheduled

## Monitoring & Maintenance

### Health Checks

```bash
# Check application health
curl https://your-domain.com/health

# Check database connectivity
MIX_ENV=prod mix ecto.migrate --check
```

### Log Monitoring

```bash
# View application logs
tail -f /var/log/financial_agent/app.log

# For Docker deployment
docker logs -f financial-agent

# For Fly.io deployment
fly logs
```

### Database Maintenance

```bash
# Run migrations
MIX_ENV=prod mix ecto.migrate

# Create database backup
pg_dump financial_agent_prod > backup_$(date +%Y%m%d).sql
```

## Performance Optimization

### Database Optimization

1. **Connection Pooling**
   - Set appropriate `POOL_SIZE` (typically 10-20)
   - Monitor connection usage

2. **Query Optimization**
   - Enable query logging for slow queries
   - Add database indexes as needed

3. **Caching**
   - Configure Redis for session storage
   - Implement application-level caching

### Application Optimization

1. **Asset Optimization**
   ```bash
   # Compress assets
   MIX_ENV=prod mix phx.digest
   ```

2. **Memory Management**
   - Monitor memory usage
   - Configure appropriate VM flags

3. **HTTP/2 and Compression**
   - Enable HTTP/2 in reverse proxy
   - Configure gzip compression

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Check `DATABASE_URL` format
   - Verify database server accessibility
   - Check SSL configuration

2. **OAuth Integration Issues**
   - Verify client IDs and secrets
   - Check redirect URLs configuration
   - Ensure proper scopes are granted

3. **Asset Loading Issues**
   - Run `mix phx.digest` after asset changes
   - Check static file serving configuration

4. **Memory Issues**
   - Monitor application memory usage
   - Adjust VM memory settings
   - Check for memory leaks

### Debug Commands

```bash
# Check application status
MIX_ENV=prod mix app.tree

# Verify configuration
MIX_ENV=prod iex -S mix

# Test database connection
MIX_ENV=prod mix ecto.migrate --check
```

## Backup Strategy

### Database Backups

```bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump financial_agent_prod | gzip > /backups/db_backup_$DATE.sql.gz

# Keep only last 30 days
find /backups -name "db_backup_*.sql.gz" -mtime +30 -delete
```

### Application Backups

```bash
# Backup uploaded files and configuration
tar -czf /backups/app_backup_$(date +%Y%m%d).tar.gz \
  /opt/financial_agent/uploads \
  /opt/financial_agent/.env.production
```

## Support

For deployment issues:
1. Check the logs for error messages
2. Verify all environment variables are set
3. Ensure database connectivity
4. Check SSL certificate validity
5. Monitor resource usage (CPU, memory, disk)

Remember to:
- Keep secrets secure and rotate them regularly
- Monitor application performance and errors
- Keep dependencies updated
- Maintain regular backups
- Test disaster recovery procedures
