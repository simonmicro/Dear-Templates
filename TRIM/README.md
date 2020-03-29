# Debian ONLY #
* `sudo cp /usr/share/doc/util-linux/examples/fstrim.{service,timer} /etc/systemd/system` _this line is not needed on buster_
* `sudo systemctl enable fstrim.timer`
* `sudo systemctl start fstrim.timer`
