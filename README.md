# Unifi-in-Docker (unifi-docker)

This repo contains a Dockerized version of [Ubiqiti Network's](https://www.ubnt.com/) Unifi Controller.

**Why bother?** Using Docker, you can stop worrying about version hassles and update notices for Unifi Controller, Java, _or_ your OS.
A Docker container wraps everything into one well-tested bundle.

To install, a couple lines on the command-line starts the container.
To upgrade, just stop the old container, and start up the new.
It's really that simple.

The latest version is Unifi Controller v8.1.127 [Change Log](https://community.ui.com/releases/UniFi-Network-Application-8-1-127/571d2218-216c-4769-a292-796cff379561)

## Setting up, Running, Stopping, Upgrading

First, install Docker on the "Docker host" - the machine that will run the Docker and Unifi Controller software.
Use any of the guides on the internet to install on your Docker host.

Then use the following steps to set up the directories and start the Docker container running.

### Setting up directories

_One-time setup:_ create the `unifi` directory on the Docker host.
Within that directory, create three sub-directories: `data`, `log` and `run`.

```bash
cd # by default, use the home directory
mkdir -p unifi/data
mkdir -p unifi/log
mkdir -p unifi/run
```

### Running

Each time you want to start Unifi, use this command.
Each of the options is [described below.](#options-on-the-command-line)

```bash
docker run -d --init \
   --restart=unless-stopped \
   -p 8080:8080 -p 8443:8443 -p 3478:3478/udp \
   -e TZ='Africa/Johannesburg' \
   -v ~/unifi/data:/unifi/data \
   -v ~/unifi/log:/unifi/log \
   -v ~/unifi/run:/unifi/run \
   --user unifi \
   --name unifi \
   ghcr.io/guymers/unifi:v8.1.127
```

In a minute or two, (after Unifi Controller starts up) you can go to
[https://docker-host-address:8443](https://docker-host-address:8443)
to complete configuration from the web (initial install) or resume using Unifi Controller.

**Important:** Two points to be aware of when you're setting up your Unifi Controller:

* When your browser initially connects to the link above, you will see a warning about an untrusted certificate.
If you are _certain_ that you have typed the address of the Docker host correctly, agree to the connection.
* See the note below about **Override "Inform Host" IP** so your Unifi devices can "find" the Unifi Controller.
 
### Upgrading Unifi Controller

All the configuration and other files created by Unifi Controller are stored on the Docker host's local disk (`~/unifi` by default.)
No information is retained within the container.
An upgrade to a new version of Unifi Controller simply retrieves a new Docker container, which then re-uses the configuration from the local disk.
The upgrade process is:

1. **MAKE A BACKUP** on another computer, not the Docker host _(Always, every time...)_
2. Stop the current container (see above)
3. Enter `docker run...` with the newer container tag

## Options on the Command Line

The options for the `docker run...` command are:

- `-d` - Detached mode: Unifi-in-Docker runs in the background
- `--init` - Recommended to ensure processes get reaped when they die
- `--restart=unless-stopped` - If the container should stop for some reason,
restart it unless you issue a `docker stop ...`
- `-p ...` - Set the ports to pass through to the container.
`-p 8080:8080 -p 8443:8443 -p 3478:3478/udp`
is the minimal set for a working Unifi Controller. 
- `-e TZ=...` Set an environment variable named `TZ` with the desired time zone.
Find your time zone in this 
[list of timezones.](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
- `-e ...` See the [Environment Variables](#environment-variables)
section for more environment variables.
- `-v ...` - Bind the volume `~/unifi` on the Docker host
to the directory `/unifi`inside the container.
**These instructions assume you placed the "unifi" directory in your home directory.**
If you created the directory elsewhere, modify the `~/unifi` part of this option to match.
See the [Volumes](#volumes) discussion for other volumes used by Unifi Controller.
- `--user unifi` - Run as a non-root user
- `guymers/unifi:<tag>` - the name of the container to use.

## Adopting Access Points and Unifi Devices

#### Override "Inform Host" IP

For your Unifi devices to "find" the Unifi Controller running in Docker,
you _MUST_ override the Inform Host IP
with the address of the Docker host computer.
(By default, the Docker container usually gets the internal address 172.17.x.x
while Unifi devices connect to the (external) address of the Docker host.)
To do this:

* Find **Settings -> System -> Other Configuration -> Override Inform Host:** in the Unifi Controller web GUI.
(It's near the bottom of that page.)
* Check the "Enable" box, and enter the IP address of the Docker host machine. 
* Save settings in Unifi Controller
* Restart UniFi-in-Docker container with `docker stop ...` and `docker run ...` commands.

## Volumes

Unifi looks for the `/unifi` directory (within the container)
for its special purpose subdirectories:

* `/unifi/data` This contains your UniFi configuration data

* `/unifi/log` This contains UniFi log files

* `/unifi/run` This contains UniFi runtime files

* `/unifi/cert` Place custom SSL certs in this directory. 
For more information regarding the naming of the certificates,
see [Certificate Support](#certificate-support)

* `/unifi/init.d`
You can place scripts you want to launch every time the container starts in here

## Environment Variables:

You can pass in environment variables using the `-e` option when you invoke `docker run...`
See the `TZ` in the example above.
Other environment variables:

* `UNIFI_HTTP_PORT`
This is the HTTP port used by the Web interface. Browsers will be redirected to the `UNIFI_HTTPS_PORT`.
**Default: 8080**

* `UNIFI_HTTPS_PORT`
This is the HTTPS port used by the Web interface.
**Default: 8443**

* `PORTAL_HTTP_PORT`
Port used for HTTP portal redirection.
**Default: 80** 

* `PORTAL_HTTPS_PORT`
Port used for HTTPS portal redirection.
**Default: 8843**

* `UNIFI_STDOUT`
Controller outputs logs to stdout in addition to server.log
**Default: true**

* `TZ`
TimeZone. (i.e America/Chicago)

* `JVM_MAX_THREAD_STACK_SIZE`
Used to set max thread stack size for the JVM
Example:

   ```
   --env JVM_MAX_THREAD_STACK_SIZE=1280k
   ```

   as a fix for [https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264](https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264)

* `LOTSOFDEVICES`
Enable this with `true` if you run a system with a lot of devices
and/or with a low powered system (like a Raspberry Pi).
This makes a few adjustments to try and improve performance: 

   * enable unifi.G1GC.enabled
   * set unifi.xms to JVM\_INIT\_HEAP\_SIZE
   * set unifi.xmx to JVM\_MAX\_HEAP\_SIZE
   * enable unifi.db.nojournal
   * set unifi.dg.extraargs to --quiet

   See [the Unifi support site](https://help.ui.com/hc/en-us/articles/115005159588-UniFi-How-to-Tune-the-Network-Application-for-High-Number-of-UniFi-Devices)
for an explanation of some of those options.
**Default: unset**

* `JVM_EXTRA_OPTS`
Used to start the JVM with additional arguments.
**Default: unset**

* `JVM_INIT_HEAP_SIZE`
Set the starting size of the javascript engine for example: `1024M`
**Default: unset**

* `JVM_MAX_HEAP_SIZE`
Java Virtual Machine (JVM) allocates available memory. 
For larger installations a larger value is recommended. For memory constrained system this value can be lowered. 
**Default: 1024M**

## Exposed Ports

The Unifi-in-Docker container exposes the following ports.
A minimal Unifi Controller installation requires you
expose the first three with the `-p ...` option.

* 8080/tcp - Device command/control 
* 8443/tcp - Web interface + API 
* 3478/udp - STUN service 
* 8843/tcp - HTTPS portal _(optional)_
* 8880/tcp - HTTP portal _(optional)_
* 6789/tcp - Speed Test (unifi5 only) _(optional)_

See [UniFi - Ports Used](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used) for more information.

## Certificate Support

To use custom SSL certs, you must map a volume with the certs to `/unifi/cert`

They should be named:

```shell
cert.pem  # The Certificate
privkey.pem # Private key for the cert
chain.pem # full cert chain
```

If your certificate or private key have different names, you can set the environment variables `CERTNAME` and `CERT_PRIVATE_NAME` to the name of your certificate/private key, e.g. `CERTNAME=my-cert.pem` and `CERT_PRIVATE_NAME=my-privkey.pem`.

For letsencrypt certs, we'll autodetect that and add the needed Identrust X3 CA Cert automatically. In case your letsencrypt cert is already the chained certificate, you can set the `CERT_IS_CHAIN` environment variable to `true`, e.g. `CERT_IS_CHAIN=true`. This option also works together with a custom `CERTNAME`.

### Certificates Using Elliptic Curve Algorithms

If your certs use elliptic curve algorithms, which currently seems to be the default with letsencrypt certs, you might additionally have to set the `UNIFI_ECC_CERT` environment variable to `true`, otherwise clients will fail to establish a secure connection. For example an attempt with `curl` will show:

```shell
% curl -vvv https://my.server.com:8443
curl: (35) error:1404B410:SSL routines:ST_CONNECT:sslv3 alert handshake failure
```

You can check your certificate for this with the following command:

```shell
% openssl x509 -text < cert.pem | grep 'Public Key Algorithm'
         Public Key Algorithm: id-ecPublicKey
```

If the output contains `id-ec` as shown in the example, then your certificate might be affected.
