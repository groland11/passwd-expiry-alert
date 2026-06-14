# passwd-expiry-alert
Send notification emails for expiring passwords of Linux PAM accounts

# How it works
   - Checks all local PAM accounts in /etc/passwd if password expires in certain amount of days
     (see variable WARNING_DAYS, adjust to your specific requirements)
   - If so, send notifiction email to user
     Email of user has to be stored in PAM field (s. prerequisites)

# Prerequisites
   - User information in /etc/passwd contain full user name and email, e.g.:
     chfn -o firstname.lastname@example.com test
     chfn -f "Firstname Lastname" test
     test:x:1001:100:Firstname Lastname,,,,firstname.lastname@example.com:/home/test:/bin/bash
   - Password expiration is set for user, e.g.:
     chage -M 180 test
     Check with: chage -l test
   - Change global variable WARNING_DAYS to your specific requirements.
     These are the days before password expiration where the notification emails will be sent to users
   - Change global variable LOGFILE to your specific requirements.
     Make sure directory does exist.
   - Working mail client /usr/bin/mail

# Parameters
   -d Debug mode. Print additional messages to stdout and logfile.
