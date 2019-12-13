# Debian ONLY #
* `sudo cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system`
* `sudo systemctl enable fstrim.timer`
* `sudo systemctl start fstrim.timer`
