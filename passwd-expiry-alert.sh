#!/bin/bash
# Script to notify local Linux users in (PAM) about password expiration
# Version: 1.0.1
#
# Prerequisites:
#   - User information in /etc/passwd contain full user name and email, e.g.:
#     chfn -o firstname.lastname@example.com test
#     chfn -f "Firstname Lastname" test
#     test:x:1001:100:Firstname Lastname,,,,firstname.lastname@example.com:/home/test:/bin/bash
#   - Password expiration is set for user, e.g.:
#     chage -M 180 test
#     Check with: chage -l test
#   - Change global variable WARNING_DAYS to your specific requirements.
#     These are the days before password expiration where the notification emails will be sent to users
#   - Change global variable LOGFILE to your specific requirements.
#     Make sure directory does exist.
#
# Parameters:
#   -d Debug mode. Print additional messages to stdout and logfile.
#

# Settings
WARNING_DAYS=(28 14 7)
HOSTNAME=$(hostname -f)
FROM_EMAIL="root@${HOSTNAME}"
MAIL_COMMAND="/usr/bin/mail"  # or /bin/mail, or /usr/bin/mailx
DEBUG=0
LOGFILE="/var/log/scripts/$(basename $0).log"

declare -a ACCOUNTS # List of all expiring accounts for statistics

# Get today epoch
NOW=$(date +%s)

# Debug mode
if [[ "$1" == "-d" ]] ; then
    DEBUG=1
fi

function log {
    DT=$(date +"%Y-%m-%d %H:%M:%S")

    # Debug messages only in debug mode
    if [[ "${DEBUG}" == "0" && $1 =~ DEBUG ]] ; then
        return
    fi

    echo "$DT $1" | /usr/bin/tee -a ${LOGFILE}
}

# Loop over local users with valid shells (excluding system accounts)
users=$(awk -F: '($7 ~ /\/bin\/bash$/ || $7 ~ /\/bin\/sh$/) && ($3 >= 1000) {print $1}' /etc/passwd)
while IFS= read -r user; do
    # Check if user has password, skip system users (UID >= 1000)
    # Get password expiry info with chage
    log "DEBUG: Checking user ${user}"
    expiry_str=$(LANG=C chage -l "$user" | grep "Password expires" | cut -d: -f2- | xargs)

    if [[ "$expiry_str" == "never" ]]; then
        log "DEBUG: Skipping $user (expiry date = $expiry_str)"
        continue
    fi

    # Convert expiry date to epoch
    expiry_epoch=$(date -d "$expiry_str" +%s 2>/dev/null)
    if [[ -z "$expiry_epoch" ]]; then
        log "DEBUG: Skipping $user (missing expiry date=$expiry_str)"
        continue
    fi

    # Calculate remaining days
    remaining_days=$(( (expiry_epoch - NOW) / 86400 ))
    log "DEBUG: Remaining days for ${user}: ${remaining_days}"

    # Checking email of user
    email=$(grep "^${user}:" /etc/passwd | cut -d: -f5 | cut -d, -f5)
    fullname=$(grep "^${user}:" /etc/passwd | cut -d: -f5 | cut -d, -f1)
    if [[ -z "$email" ]]; then
        log "WARNING: Email for $user = $email"
        continue
    fi

    # Check date
    found=0
    for n in "${WARNING_DAYS[@]}"; do
        if [[ $n -eq $remaining_days ]]; then
            found=1
            break
        fi
    done

    if (( found == 1 && remaining_days >= 0 )); then
        log "INFO: Password for $user expires in $remaining_days day(s) (expiration date=$expiry_str)"
        log "INFO: Sending notification for $user to $email"

        # Send notification email to user
        subject="Proxmox: Password expiring for local user account"
        body="Hello $fullname,\n\nyour password for your local Linux account (PAM) on $HOSTNAME is set to expire in $remaining_days day(s) on $expiry_str.\n\nPlease change it soon."
        echo -e "$body" | $MAIL_COMMAND -s "$subject" "$email"
        RET=$?
        if [[ $RET == 0 ]] ; then
            log "INFO: Notification sent to $email for $user"
        else
            log "ERROR: Unable to send notification to $email for $user ($MAIL_COMMAND=$RET)"
        fi
    else
        log "DEBUG: Skipping $user - password expires in $remaining_days day(s) (expiration date=$expiry_str)"
    fi

    # Save all expiring users for later statistical use (see below)
    if (( remaining_days <= 7 && remaining_days >= 0 )); then
        if [[ ! -z "$fullname" ]]; then
            ACCOUNTS+=("$fullname")
        else
            ACCOUNTS+=("$user")
        fi
    fi
done <<< "$users"

# TODO: Send status email for expiring accounts


