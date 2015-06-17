---
layout: post
title: The Docker Wormhole Pattern
---

Building a Docker wormhole is easy.
<!-- more -->

> A wormhole is a special type of structure that some scientists think might exist, connecting parts of space and time that are not usually connected
>  
> --- Cambridge Dictionaries Online

In Docker universe we have several uses cases, which require a Docker installation within a Docker container. For example the [OpenShift Builds][1] use images whose container's are meant to create application images. They include a whole development environment including possibly a compiler and a build tool. During the build a Docker daemon is accessed for creating the final application image.

The question is now, *how* a build can access the Docker daemon ? In general, there are two possibilities:

* [Docker in Docker][2] is a project which allows you to run a Docker daemon within a Docker container. Technically this is quite tricky and there seems to be some issues with this approach, especially because you have to run this container in [privileged mode][3]. This is the **Matryoshka doll pattern**.
* Or you use the **Wormhole pattern** described in this post. The idea is to get access to the Docker daemon running a container from within the container.

As you know a Docker host can be configured to be accessible by two alternative methods: Via a Unix socket or via a TCP socket.

Using the Unix socket of the surrounding docker daemon is easy: Simply share the path to the unix socket as a volume:

	# Map local unix socket into the container
	docker run -it -v /var/run/docker.sock:/var/run/docker.sock ...

Then within the container you can use the Docker CLI or any tool that uses the Unix socket at usual. 

Running over the TCP socket is a bit more tricky because you have to find out the address of your Docker daemon host. This can best be done by examining the routing table within the container:

	# Lookup and parse routing table 
	host=$(ip route show 0.0.0.0/0 | \
	   grep -Eo 'via \S+' | \
	   awk '{print $2}');
	export DOCKER_HOST=tcp://${host}:2375

This works fine as long you are not using SSL. With SSL in place  you need have access to the SSL client certificates. Of course this is achieved again with a volume mount. Assuming that you are using boot2docker this could look like

	# Mount certs into the container
	docker run -ti -v \~/.boot2docker/certs/boot2docker-vm/:/certs ....

This will mount your certs at `/certs` within the container and can be used to set the `DOCKER_HOST` variable.


	if [ -f /certs/key.pem ]; then
	 # If certs are mounted, use SSL ...
	 export DOCKER_CERT_PATH=/certs
	 export DOCKER_TLS_VERIFY=1
	 export DOCKER_HOST=tcp://${host}:2376
	else
	 # ... otherwise use plain http
	 export DOCKER_TLS_VERIFY=0
	 export DOCKER_HOST=tcp://${host}:2375
	fi

There is some final gotcha as that the server certificate can not be verified because it doesn't contain the docker host IP as seen from the container. See this [issue][4] for details. As workaround you have to `unset DOCKER_TLS_VERIFY` for the moment when using the docker client.

Both ways are useful and are [leaner and possibly more secure][5] than having a Matryoshka doll approach.

Finally there is still the question, why on earth *wormhole pattern* ? Like in a wormhole (also known as [Einstein-Rosen Bridge][6]) you can reach through the wormhole a point (the outer docker daemon) in spacetime which is normally not reachable (because a container is supposed to be its "own" world). Another fun fact: If you create a container through a wormhole this container it's not your daughter, its your sister. Feels a bit freaky, or ? Alternatively you could call it also **Münchhausen pattern**  because you create something with the exact the identically means you have been created yourself (like in the [Münchhausen trilemma][7]). 

Or feel free to call it what you like ;-)

[1]:	https://github.com/openshift/origin/blob/master/docs/builds.md#openshift-builds
[2]:	https://github.com/jpetazzo/dind
[3]:	http://blog.docker.com/2013/09/docker-can-now-run-within-docker/
[4]:	https://github.com/docker/docker/issues/13922
[5]:	https://github.com/openshift/origin/blob/master/docs/builds.md#why-not-docker-in-docker
[6]:	https://en.wikipedia.org/wiki/Wormhole
[7]:	https://en.wikipedia.org/wiki/M%C3%BCnchhausen_trilemma