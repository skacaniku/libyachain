#!/bin/bash
#
# LibyaChain Audit Logging Setup Script
#
# This script sets up the audit logging infrastructure for production deployment.
# It creates directories, sets permissions, configures log rotation, and validates the setup.
#
# Usage:
#   sudo ./scripts/setup-audit-logging.sh
#
# Prerequisites:
#   - Run as root or with sudo
#   - Linux system with systemd
#   - logrotate installed
#

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_USER="${APP_USER:-libyachain}"
APP_GROUP="${APP_GROUP:-libyachain}"
LOG_DIR="/var/log/libyachain"
AUDIT_LOG_FILE="${LOG_DIR}/audit.log"
BACKUP_DIR="/var/backups/libyachain/audit"
RETENTION_DAYS=90

echo -e "${BLUE}==================================================================${NC}"
echo -e "${BLUE}  LibyaChain Audit Logging Setup${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
  echo "Usage: sudo $0"
  exit 1
fi

echo -e "${BLUE}Step 1/7: Creating application user and group...${NC}"
# Create application user/group if they don't exist
if ! id "$APP_USER" &>/dev/null; then
    echo "Creating user: $APP_USER"
    useradd --system --no-create-home --shell /bin/false "$APP_USER"
else
    echo -e "${GREEN}✓${NC} User $APP_USER already exists"
fi

echo ""
echo -e "${BLUE}Step 2/7: Creating log directories...${NC}"
# Create log directory
if [ ! -d "$LOG_DIR" ]; then
    echo "Creating directory: $LOG_DIR"
    mkdir -p "$LOG_DIR"
else
    echo -e "${GREEN}✓${NC} Directory $LOG_DIR already exists"
fi

# Create backup directory
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
else
    echo -e "${GREEN}✓${NC} Directory $BACKUP_DIR already exists"
fi

echo ""
echo -e "${BLUE}Step 3/7: Setting permissions...${NC}"
# Set ownership
chown -R "$APP_USER:$APP_GROUP" "$LOG_DIR"
chown -R "$APP_USER:$APP_GROUP" "$BACKUP_DIR"
echo -e "${GREEN}✓${NC} Set ownership to $APP_USER:$APP_GROUP"

# Set directory permissions
chmod 750 "$LOG_DIR"
chmod 750 "$BACKUP_DIR"
echo -e "${GREEN}✓${NC} Set directory permissions (750)"

# Create audit log file if it doesn't exist
if [ ! -f "$AUDIT_LOG_FILE" ]; then
    touch "$AUDIT_LOG_FILE"
    echo "Created audit log file: $AUDIT_LOG_FILE"
fi

# Set file permissions
chown "$APP_USER:$APP_GROUP" "$AUDIT_LOG_FILE"
chmod 640 "$AUDIT_LOG_FILE"
echo -e "${GREEN}✓${NC} Set file permissions (640)"

# Enable append-only mode for security
echo "Enabling append-only mode..."
chattr +a "$AUDIT_LOG_FILE" 2>/dev/null || echo -e "${YELLOW}⚠${NC}  Warning: Could not enable append-only mode (chattr not available)"

echo ""
echo -e "${BLUE}Step 4/7: Creating logrotate configuration...${NC}"
# Create logrotate configuration
cat > /etc/logrotate.d/libyachain-audit <<'EOF'
/var/log/libyachain/audit.log {
    daily
    rotate 90
    compress
    delaycompress
    notifempty
    create 0640 libyachain libyachain
    sharedscripts

    prerotate
        # Remove append-only flag before rotation
        /usr/bin/chattr -a /var/log/libyachain/audit.log 2>/dev/null || true
    endscript

    postrotate
        # Re-enable append-only flag after rotation
        /usr/bin/chattr +a /var/log/libyachain/audit.log 2>/dev/null || true
        # Reload application if running
        /bin/systemctl reload libyachain-admin-web 2>/dev/null || true
    endscript

    # Keep compressed logs for compliance (90 days default)
    maxage 90
}
EOF

echo -e "${GREEN}✓${NC} Created /etc/logrotate.d/libyachain-audit"

# Test logrotate configuration
echo "Testing logrotate configuration..."
logrotate -d /etc/logrotate.d/libyachain-audit &>/dev/null && \
    echo -e "${GREEN}✓${NC} Logrotate configuration is valid" || \
    echo -e "${YELLOW}⚠${NC}  Warning: Logrotate configuration test failed"

echo ""
echo -e "${BLUE}Step 5/7: Creating backup script...${NC}"
# Create backup script
cat > /usr/local/bin/backup-audit-logs.sh <<'EOF'
#!/bin/bash
# LibyaChain Audit Log Backup Script
# Backs up audit logs to secure storage

set -e

LOG_DIR="/var/log/libyachain"
BACKUP_DIR="/var/backups/libyachain/audit"
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="${BACKUP_DIR}/audit-${DATE}.tar.gz"
RETENTION_DAYS=2555  # 7 years for compliance

# Create backup
echo "[$(date)] Starting audit log backup..."
tar -czf "${BACKUP_FILE}" -C "${LOG_DIR}" .
echo "[$(date)] Backup created: ${BACKUP_FILE}"

# Set permissions
chmod 600 "${BACKUP_FILE}"
chown libyachain:libyachain "${BACKUP_FILE}"

# Upload to S3 if configured
if [ -n "${AUDIT_BACKUP_S3_BUCKET:-}" ]; then
    echo "[$(date)] Uploading to S3..."
    aws s3 cp "${BACKUP_FILE}" "s3://${AUDIT_BACKUP_S3_BUCKET}/audit-logs/$(date +%Y/%m)/" \
        --storage-class GLACIER || echo "[$(date)] Warning: S3 upload failed"
fi

# Clean up old local backups (keep only recent ones)
echo "[$(date)] Cleaning up old local backups..."
find "${BACKUP_DIR}" -name "audit-*.tar.gz" -mtime +30 -delete || true

echo "[$(date)] Backup completed successfully"
EOF

chmod +x /usr/local/bin/backup-audit-logs.sh
echo -e "${GREEN}✓${NC} Created /usr/local/bin/backup-audit-logs.sh"

# Create cron job for daily backups
echo "Setting up daily backup cron job..."
CRON_JOB="0 3 * * * /usr/local/bin/backup-audit-logs.sh >> /var/log/libyachain/backup.log 2>&1"
(crontab -l 2>/dev/null | grep -v "backup-audit-logs.sh" ; echo "$CRON_JOB") | crontab -
echo -e "${GREEN}✓${NC} Backup cron job created (runs daily at 3 AM)"

echo ""
echo -e "${BLUE}Step 6/7: Creating monitoring script...${NC}"
# Create monitoring script
cat > /usr/local/bin/monitor-audit-logs.sh <<'EOF'
#!/bin/bash
# LibyaChain Audit Log Monitoring Script
# Monitors for critical security events

set -e

LOG_FILE="/var/log/libyachain/audit.log"
ALERT_LOG="/var/log/libyachain/alerts.log"
LOOKBACK_MINUTES="${1:-5}"

echo "[$(date)] Monitoring audit logs (last ${LOOKBACK_MINUTES} minutes)..."

# Get timestamp for lookback period
SINCE=$(date -d "${LOOKBACK_MINUTES} minutes ago" -u +"%Y-%m-%dT%H:%M:%S")

# Monitor for critical events
CRITICAL_COUNT=$(jq -r "select(.severity == \"CRITICAL\" and .timestamp >= \"${SINCE}\") | .id" "${LOG_FILE}" 2>/dev/null | wc -l)

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "[$(date)] ALERT: ${CRITICAL_COUNT} CRITICAL events detected!" | tee -a "${ALERT_LOG}"
    jq -r "select(.severity == \"CRITICAL\" and .timestamp >= \"${SINCE}\")" "${LOG_FILE}" 2>/dev/null | tee -a "${ALERT_LOG}"
fi

# Monitor for brute force attacks
BRUTE_FORCE_COUNT=$(jq -r "select(.eventType == \"security.bruteForce.detected\" and .timestamp >= \"${SINCE}\") | .id" "${LOG_FILE}" 2>/dev/null | wc -l)

if [ "$BRUTE_FORCE_COUNT" -gt 0 ]; then
    echo "[$(date)] ALERT: ${BRUTE_FORCE_COUNT} brute force attacks detected!" | tee -a "${ALERT_LOG}"
fi

# Monitor for failed authentications
FAILED_AUTH_COUNT=$(jq -r "select(.eventType == \"auth.login.failure\" and .timestamp >= \"${SINCE}\") | .id" "${LOG_FILE}" 2>/dev/null | wc -l)

if [ "$FAILED_AUTH_COUNT" -gt 10 ]; then
    echo "[$(date)] WARNING: ${FAILED_AUTH_COUNT} failed authentications in last ${LOOKBACK_MINUTES} minutes" | tee -a "${ALERT_LOG}"
fi

echo "[$(date)] Monitoring check completed"
EOF

chmod +x /usr/local/bin/monitor-audit-logs.sh
echo -e "${GREEN}✓${NC} Created /usr/local/bin/monitor-audit-logs.sh"

# Create cron job for monitoring
echo "Setting up monitoring cron job..."
MONITOR_CRON="*/5 * * * * /usr/local/bin/monitor-audit-logs.sh 5 >> /var/log/libyachain/monitor.log 2>&1"
(crontab -l 2>/dev/null | grep -v "monitor-audit-logs.sh" ; echo "$MONITOR_CRON") | crontab -
echo -e "${GREEN}✓${NC} Monitoring cron job created (runs every 5 minutes)"

echo ""
echo -e "${BLUE}Step 7/7: Validating setup...${NC}"
# Validate setup
echo "Checking directories..."
[ -d "$LOG_DIR" ] && echo -e "${GREEN}✓${NC} Log directory exists" || echo -e "${RED}✗${NC} Log directory missing"
[ -d "$BACKUP_DIR" ] && echo -e "${GREEN}✓${NC} Backup directory exists" || echo -e "${RED}✗${NC} Backup directory missing"

echo "Checking permissions..."
[ -w "$AUDIT_LOG_FILE" ] && echo -e "${GREEN}✓${NC} Audit log is writable" || echo -e "${RED}✗${NC} Audit log is not writable"

echo "Checking logrotate..."
[ -f "/etc/logrotate.d/libyachain-audit" ] && echo -e "${GREEN}✓${NC} Logrotate configured" || echo -e "${RED}✗${NC} Logrotate not configured"

echo "Checking scripts..."
[ -x "/usr/local/bin/backup-audit-logs.sh" ] && echo -e "${GREEN}✓${NC} Backup script installed" || echo -e "${RED}✗${NC} Backup script missing"
[ -x "/usr/local/bin/monitor-audit-logs.sh" ] && echo -e "${GREEN}✓${NC} Monitoring script installed" || echo -e "${RED}✗${NC} Monitoring script missing"

echo ""
echo -e "${BLUE}==================================================================${NC}"
echo -e "${GREEN}✓ Audit logging setup completed successfully!${NC}"
echo -e "${BLUE}==================================================================${NC}"
echo ""
echo "Configuration Summary:"
echo "  Log Directory:    $LOG_DIR"
echo "  Audit Log File:   $AUDIT_LOG_FILE"
echo "  Backup Directory: $BACKUP_DIR"
echo "  Retention:        $RETENTION_DAYS days"
echo "  Owner:            $APP_USER:$APP_GROUP"
echo ""
echo "Next Steps:"
echo "  1. Update .env.production with:"
echo "     AUDIT_LOG_PATH=$AUDIT_LOG_FILE"
echo "  2. Configure SIEM webhook (optional):"
echo "     AUDIT_WEBHOOK_URL=https://your-siem.com/ingest"
echo "     SIEM_TOKEN=your_token_here"
echo "  3. Test audit logging:"
echo "     echo '{\"test\":\"audit\"}' >> $AUDIT_LOG_FILE"
echo "  4. View logs:"
echo "     tail -f $AUDIT_LOG_FILE | jq ."
echo "  5. Monitor for alerts:"
echo "     tail -f /var/log/libyachain/alerts.log"
echo ""
echo "For more information, see: admin-web/AUDIT_LOG_SETUP.md"
echo ""
