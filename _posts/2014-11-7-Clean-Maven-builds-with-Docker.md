---
layout: post
title: Real clean Maven builds with Docker
---

A local Maven repository serves as a cache for artifacts and dependencies, we all know this. This helps in speeding up things but can cause subtle problems when doing releases. Docker can help here a bit for avoiding caching issues.
<!-- more -->

Before doing a release I typically move `~/.m2/repository` away to be really sure that everybody else can build the source as well and that any dependencies are also on the remote Maven repository. This is a bit tedious, because it is a manual process and you can forget to move the old directory back which will was a LOT of disk space over time.

Docker can help here a bit: Since yesterday there is an [official Maven image][1] which can be used to build your project. The nice thing for doing releases with this image is, that it always starts afresh with an empty local Maven repository. 

Assuming you are currently located in the top-level directory holding your `pom.xml` you can use this single command for running a real clean build:

	docker run -it --rm \ 
		  -v "$(pwd)":/usr/src/mymaven  \ 
		  -w /usr/src/mymaven \ 
		  maven:3.2-jdk-7 \
		  mvn clean install

With this call you mount your project directory into `/usr/src/mymaven` on the container, change to this directory in the container and call `mvn clean install`. At the end, your container will be removed (`--rm`) so there is no chance that you might forget to clean up afterwards.

Of course it will download all the artifacts each time, so it is not a good idea to use this approach for your daily developer business (especially if you using Maven central as remote Maven repository).

You can also play around with various versions of Maven by changing the image tag so at the end you can be really sure, that your project will build everywhere. Please refer to the [Docker Hub page][2] for details. 

**Update**: As pointed out by [Noah Zucker][3] on Twitter you can redirect of course the local repository via `-Dmaven.repo.local=/tmp/clean-repo` temporarily to a new location. Which is confessedly much simpler and I would prefer that one instead if you don't need to check with different JDKs or Maven versions. Sometimes you don't see the forest for the trees if you come from the wrong direction (e.g. looking for use case of a specific docker image).

[1]:	https://registry.hub.docker.com/_/maven/
[2]:	https://registry.hub.docker.com/_/maven/
[3]:	https://twitter.com/noahlz/status/530708791906807808