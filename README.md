
## Development

Alces Access Manager Daemon is designed to be run within a Clusterware
environment; a Vagrantfile to use during development is available at
https://github.com/alces-software/alces-access-manager/dev/multiple-nodes-el7/login-el7/Vagrantfile.

Setting up for development within daemon directory in Clusterware environment:

- Install RVM: https://rvm.io/
- Install dependencies:

  ```
  rvm install ruby-2.2.1
  cd /media/host/alces-access-manager-daemon
  gem install bundler
  sudo yum install git pam-devel ruby-devel -y
  bundle install
  ```

Running the daemon:

```
/media/host/script/develop-daemon
```

To forward daemon port:

```
ssh -L 25269:10.0.2.15:25269 -p 2222 vagrant@localhost
```
