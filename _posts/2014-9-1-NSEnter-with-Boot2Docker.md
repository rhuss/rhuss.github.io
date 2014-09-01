---
layout: post
title: Using NSEnter with Boot2Docker
---

[NSEnter][1] is a nice way to connect to a running Docker container. This post presents a script to ease the usage of `nsenter` together with [Boot2Docker][2].
<!-- more -->

There is still quite some dust around Docker and day after day after gaining more and more experience, new patterns and anti-patterns are emerging. 

One of those anti-patterns is the usage of an SSH daemon inside an image for debugging, backup and troubleshooting purposes. Jérôme Petazzoni's [Blog Post][3] explains this nicely. In addition it provides proper solutions for common use cases SSH is currently used for.

Nevertheless there I still have this irresistible urge to login into a container. And if it is only for looking around and examine the environment (call me old-fashioned, that's ok ;-)

Luckily Jérôme provides a solution to satisfy this thirst: [nsenter][4]. This allows you to **enter** into container **n**ame**s**paces. On the GitHub page you find the corresponding recipe for installing and using `nsenter` on a Linux host. 

If you want to use it from OS X with e.g. [Boot2Docker][5] you need to login into the VM hosting the Docker daemon and the connect to a running container.

This works but it is somewhat inconvenient. Therefore I've written a small shell script [docker-sh][6] which runs on the *OS X host* and uses `boot2docker ssh -t` for connecting to a running container. As arguments it expects a container id or name and optionally a command to execute in the container.  This script also will automatically install `nsenter`  on the boot2docker VM if not already present: 

```bash
	10:20 [~] $ docker ps -q
	5bf8a161cceb
	10:20 [~] $ docker-sh 5bf8a161cceb bash
	Unable to find image 'jpetazzo/nsenter' locally
	Pulling repository jpetazzo/nsenter
	Installing nsenter to /target
	Installing docker-enter to /target
	root@5bf8a161cceb:/#
```

Furthermore a small Bash completion script [docker-sh_commands][7] (inspired by [Docker's bash completion][8]) completes on container names and ids on the arguments for `docker-sh`.

The scripts are not perfect, though (my shell fu got a bit rusty ;-). I highly appreciate any improvement, please comment and/or send pull request, I will update them accordingly.

[1]:	https://github.com/jpetazzo/nsenter
[2]:	https://github.com/boot2docker/boot2docker
[3]:	https://blog.docker.com/2014/06/why-you-dont-need-to-run-sshd-in-docker/
[4]:	https://github.com/jpetazzo/nsenter
[5]:	https://github.com/boot2docker/boot2docker
[6]:	https://gist.github.com/rhuss/a8a40bd143001fd5c83c#file-docker-sh
[7]:	https://gist.github.com/rhuss/a8a40bd143001fd5c83c#file-docker-sh_commands
[8]:	https://github.com/docker/docker/blob/master/contrib/completion/bash/docker