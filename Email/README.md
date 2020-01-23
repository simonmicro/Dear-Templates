# Setup #
...debian to send all emails received with `mail`.
1. Install `mailutils` / `exim4` (Both required!)
2. `sudo nano /etc/aliases`
3. Add desired target: `[USERNAME]: [EMAIL]`
4. Run `sudo dpkg-reconfigure exim4-config` and select internet site (confirm everything with return...)
5. Enjoy.
