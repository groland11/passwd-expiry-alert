# passwd-expiry-alert
Send notification emails for expiring passwords of Linux PAM accounts

# How it works
   - Checks all local PAM accounts in /etc/passwd if password expires in certain amount of days<br/>
     (see variable WARNING_DAYS, adjust to your specific requirements)
   - If so, send notifiction email to user<br/>
     Email of user has to be stored in PAM field (s. prerequisites)

# Prerequisites
   - User information in /etc/passwd contain full user name and email, e.g.:<br/>
     chfn -o firstname.lastname@example.com test<br/>
     chfn -f "Firstname Lastname" test<br/>
     test:x:1001:100:Firstname Lastname,,,,firstname.lastname@example.com:/home/test:/bin/bash
   - Password expiration is set for user, e.g.:<br/>
     chage -M 180 test<br/>
     Check with: chage -l test
   - Change global variable WARNING_DAYS to your specific requirements.<br/>
     These are the days before password expiration where the notification emails will be sent to users
   - Change global variable LOGFILE to your specific requirements.<br/>
     Make sure directory does exist.
   - Working mail client /usr/bin/mail

# Parameters
   -d Debug mode. Print additional messages to stdout and logfile.
