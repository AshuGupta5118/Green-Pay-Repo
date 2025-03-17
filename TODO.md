# Green Pay Backend Deployment TODO

## Heroku Setup
1. Create a free Heroku account at https://signup.heroku.com/
2. Create a new app named "green-pay-api"
3. Get Heroku API key from Account Settings
4. Set up GitHub repository secrets:
   - `HEROKU_API_KEY`
   - `HEROKU_APP_NAME`
   - `HEROKU_EMAIL`

## GitHub Configuration
1. Create a Personal Access Token:
   - Go to Settings > Developer settings > Personal access tokens
   - Create token with 'repo' scope
   - Save as `GITHUB_TOKEN` in repository secrets
2. Update `.env` file:
   ```
   GITHUB_OWNER=<your-github-username>
   GITHUB_REPO=green-pay
   ```
3. Enable GitHub Container Registry:
   - Go to repository Settings
   - Packages > Enable GitHub Container Registry

## MongoDB Setup
1. Create free MongoDB Atlas account:
   - Visit https://www.mongodb.com/cloud/atlas
   - Create new cluster (free tier)
   - Set up database user and password
   - Whitelist IP addresses
2. Get connection string and update `.env`:
   ```
   MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/green_pay
   ```

## Security Configuration
1. Generate strong JWT secret:
   ```
   JWT_SECRET=<generate-strong-secret>
   ```
2. Update CORS settings in `.env`:
   ```
   CORS_ORIGIN=<your-frontend-url>
   ```
3. Configure rate limiting:
   ```
   RATE_LIMIT_WINDOW_MS=900000
   RATE_LIMIT_MAX_REQUESTS=100
   AUTH_RATE_LIMIT_WINDOW_MS=3600000
   AUTH_RATE_LIMIT_MAX_ATTEMPTS=5
   ```

## UPI Integration
1. Get UPI merchant credentials
2. Update `.env`:
   ```
   UPI_MERCHANT_ID=<your-merchant-id>
   UPI_MERCHANT_NAME=GreenPay
   ```

## Monitoring Setup
1. Set up free monitoring services:
   - Create Sentry.io account for error tracking
   - Set up UptimeRobot for uptime monitoring
   - Configure LogRocket for session replay (optional)

## SSL/TLS Setup
1. Verify Heroku SSL configuration
2. Set up Let's Encrypt if using custom domain

## Backup Configuration
1. Set up GitHub Actions schedule for regular backups:
   - Update workflow to run backup script daily
   - Configure backup retention policy
   - Test backup and restore procedures

## Testing
1. Run test suite:
   ```bash
   npm test
   ```
2. Verify test coverage meets requirements
3. Add any missing test cases

## Documentation
1. Review and update API documentation
2. Verify Swagger UI is accessible
3. Add postman collection for API testing

## Frontend-Backend Integration
1. Configure environment variables:
   ```
   API_URL=http://localhost:3000/api  # Development
   API_URL=https://green-pay-api.herokuapp.com/api  # Production
   ```
2. Test API endpoints:
   - Authentication (login/register)
   - Payment processing
   - UPI integration
   - User profile management
3. Implement error handling:
   - Network errors
   - API errors
   - Authentication errors
4. Add loading states:
   - During API calls
   - Payment processing
   - Authentication
5. Test cross-origin requests:
   - Verify CORS configuration
   - Test from different environments

## Final Checklist
- [ ] All environment variables configured
- [ ] Database connection tested
- [ ] API endpoints tested
- [ ] Backups configured and tested
- [ ] Monitoring set up
- [ ] SSL/TLS verified
- [ ] Documentation complete
- [ ] CI/CD pipeline working
- [ ] Security measures implemented
- [ ] Rate limiting tested
- [ ] CORS configured correctly

## Notes
- Keep backup of all credentials and tokens
- Document any custom configurations
- Monitor free tier limits
- Set up alerts for critical issues
- Plan for scaling if needed 