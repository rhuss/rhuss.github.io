---
layout: post
title: Using NSEnter with Boot2Docker
---

[NSEnter][1] is a nice way to connect to a running Docker container. This post presents a script to simplify the usage of `nsenter` together with [Boot2Docker][2].
<!-- more -->

There is still quite some dust around Docker and after gaining more and more experience, new patterns and anti-patterns are emerging. 

One of those anti-patterns is the usage of an SSH daemon inside an image for debugging, backup and troubleshooting purposes. Jérôme Petazzoni's [Blog Post][3] explains this nicely. In addition it provides proper solutions for common use cases for which SSH is currently used.

Nevertheless I still have this irresistible urge to login into a container. And if it is only for looking around and checking out the environment (call me old-fashioned, that's ok ;-)

Luckily Jérôme provides a perfect solution to satisfy this thirst: [nsenter][4]. This allows you to **enter** into container **n**ame**s**paces. On the GitHub page you find the corresponding recipe for installing and using `nsenter` on a Linux host. 

If you want to use it from OS X with e.g. [Boot2Docker][5] you need to login into the VM hosting the Docker daemon and then connect to a running container.

As described in the [NSenter README][6] you can use a simple alias for doing this transparently

```bash
	docker-enter() {
	  boot2docker ssh '[ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /var/lib/boot2docker/:/target jpetazzo/nsenter'
	  boot2docker ssh -t sudo /var/lib/boot2docker/docker-enter "$@"
	}
```

For a bit more comfort with usage information and error checking you can convert this to a small shell script like [docker-enter][7] which needs to be installed within the path (on OS X). As arguments it expects a container id or name and optionally a command (with args) to execute in the container.  This script also will automatically install `nsenter` on the boot2docker VM if not already present (like the shell function above does this as well): 

```bash
	10:20 [~] $ docker ps -q
	5bf8a161cceb
	
	10:20 [~] $ docker-enter 5bf8a161cceb bash
	
	Unable to find image 'jpetazzo/nsenter' locally
	Pulling repository jpetazzo/nsenter
	Installing nsenter to /target
	Installing docker-enter to /target
	
	root@5bf8a161cceb:/#
```

If you want even more comfort with bash completion you 
can add the small Bash completion script [docker-enter\_commands][8] (inspired by and copied from [Docker's bash completion][9]) to your `~/.bash_completion_scripts/` directory (or wherever your completion scripts are located, e.g. `/usr/local/etc/bash_completion.d` if you installed `bash-completion` via brew). This setup completes on container names and ids on the arguments for `docker-enter`. Alternatively you can put the commands together with the shell function code above directly into your `~/.bashrc`, too.

*P.S. After writing this post, I found out, that this topic was already covered in another [blog post][10] previously by Lajos Papp. That's also where the shell function definition in the `nsenter` README originates from. Give credit to whom it’s due.*


[1]:	https://github.com/jpetazzo/nsenter
[2]:	https://github.com/boot2docker/boot2docker
[3]:	https://blog.docker.com/2014/06/why-you-dont-need-to-run-sshd-in-docker/
[4]:	https://github.com/jpetazzo/nsenter
[5]:	https://github.com/boot2docker/boot2docker
[6]:	https://github.com/jpetazzo/nsenter#docker-enter-with-boot2docker
[7]:	https://gist.github.com/rhuss/a8a40bd143001fd5c83c#file-docker-enter
[8]:	https://gist.github.com/rhuss/a8a40bd143001fd5c83c#file-docker-enter_commands
[9]:	https://github.com/docker/docker/blob/master/contrib/completion/bash/docker
[10]:	http://blog.sequenceiq.com/blog/2014/07/05/docker-debug-with-nsenter-on-boot2docker/