# Alces Access Manager Daemon
Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd. See LICENSE.txt.


## Description
Alces Access Manager Daemon is the backend to the Alces access Manager, a
web-based file manager designed to provide users with a means to manage
uploading, downloading and manipulating files in their cluster storage via
their web browser.

The ASM Daemon provides PAM-based authentication and filesystem access to the
ASM web application.

## Configuration
Alces Access Manager Daemon is a Ruby application. You must have Ruby
installed before installing Alces Access Manager Daemon.

1. Clone the git repository:

   ```$ git clone git@github.com:alces-software/alces-access-manager-daemon.git```

2. From your repository, install Ruby dependencies with bundler:

   ```$ bundle install```

  You may need to install the libpam development libraries for the above to
  succeed (needed for the `rpam-ruby19` gem). On Debian/Ubuntu this can be
  done with:

  ```$ apt-get install libpam0g-dev```

  On Red Hat/Fedora:

  ```$ yum install pam-devel```

  Other Operating Systems or distributions may vary.

3. Configure the Access Manager Daemon by editing the
  `config/access-manager-daemon.yml`file. A sample configuration file is
  provided at `config/access-manager-daemon.yml.ex`. The options within this
  file are as follows:
    * `interfaces`: List of network interfaces (by IP address) for the daemon to
    listen on. The wildcard `*` binds to all interfaces.
    * `port`: The port on which to listen. Default is `25268`.
    * `log_file`: Path to log file. Defaults to `log/daemon.log`.
    * `configs`: Additional configuration files to load. The SSL configuration is
      included in this way. A `.yml` file extension is assumed.

4. Ensure PAM is configured to allow ASMD to authenticate. This can usually be
   done by copying the file in `config/etc/pam.d` into the `/etc/pam.d/`
   directory and restarting PAM.

5. Start Alces Access Manager Daemon by running as root
   ```# ./bin/alces-access-manager-daemon```

In production environments, it is often desirable to run ASMD as a persistent
daemon. An init script is provided in `config/etc/init.d` for this purpose.

## Defining storage targets

 There are two ways of defining storage 'targets' - that is, storage volumes
 that appear in the file manager - system-wide and user-specifically.

### Defining system-wide targets

 ASMD looks in the `/etc/xdg/clusterware/storage/` directory for configuration
 files that apply to all users. Users will keep their user privileges so you
 will still need to ensure that they have suitable permissions on the relevant
 filesystem(s).

### Defining user-specific targets

 Users may create target configuration files in their
 `~/.config/clusterware/storage/` directories (on the system running the ASM
 daemon).

### Target file format

 The target specification files are YAML and each describe a single storage
 volume. They should be called `<name>.target.yml`.

 Example:

 ```
 ---
name: "Home"
type: posix
dir: "%#{dir}/"
address: "127.0.0.2:25268"
```

#### Options common to all types

* `name` - **Required**. Unique identifying string for this target.
* `type` - **Required**. Type of connection. Must be one of `posix` or `s3`.
* `address` - for `posix` targets, the IP address and port of the running ASM
daemon providing this volume, and defaults to the daemon configured for
authentication in the Storage Manager application. For `s3` targets, the
address of the S3-compatible gateway; defaults to Amazon's AWS S3 service.
* `sortKey` - when present, this will be used instead of `name` to determine
the ordering of the target. Targets are returned sorted alphabetically, and
system targets are always returned before user targets.

#### Options specific to 'posix' targets

* `dir` - **Required**. Directory that is the root of this target. May either be a literal
path such as `/opt/somefolder/` or use a Ruby-style hash string replacement
to include variables such as the user's name, home directory or the system temp
directory; for example `%#{dir}/` for their home directory, or
`%/scratch/#{name}/` to represent a user's named directory under `/scratch`.
* `ssl` - Boolean flag for whether or not to use an SSL connection. Defaults to
true.

#### Options specific to 's3' targets

* `access_key` - **Required**. The access key from the AWS credentials to be used.
* `secret_key` - **Required**. The secret key from the AWS credentials to be used.
* `buckets` - List of additional public buckets to include in the volume. For
example, `['1000genomes']` will include read-only access to the 1000 Genomes
project bucket, one of several data sets made available by Amazon. See
https://aws.amazon.com/datasets/ for more details.
