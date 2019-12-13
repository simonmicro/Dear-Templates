# HowTo: Security #

## Hide Apache Version and OS Identity ##
1. `sudo nano /etc/apache2/apache2.conf`
2. Append:
    ```
    ServerSignature Off
    ServerTokens Prod
    ```
