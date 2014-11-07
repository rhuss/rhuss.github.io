---
layout: post
title: Real clean Maven builds with Docker
---

A local Maven repository serves as a cache for artifacts and dependencies, you all know this. This helps in speeding up thing but can cause subtle problems when doing releases. Docker can help here a bit for avoiding these caching issues.
<!-- more -->

Before doing a release I typically move `~/.m2/repository` away to be really sure that everybody else can build the source as well and that any dependencies are also on the remote Maven repository even if they were installed locally. This is a bit tedious, because its a manual process and you can forget to move the old directory back.

Docker can help here a bit: Since yesterday there is an [official Maven image][1] which can be used to build your project. The nice thing for doing releases is, that it always starts afresh with an empty local Maven repository. 

Assuming you are currently located in the top-level directory holding your `pom.xml` you can use this single command for running a real clean build:

````bash
docker run -it --rm \ 
      -v "$(pwd)":/usr/src/mymaven  \ 
      -w /usr/src/mymaven \ 
      maven:3.2-jdk-7 \
      mvn clean install
````

With this call you mount your project directory into `/usr/src/mymaven` on the container (which will be created for you), change to this directory in the container and call `mvn clean install`. At the end, your container will be removed (`--rm`) so there is no chance that you might forget to clean up afterwards.

Of course it will download all the artifacts each time, so it is not a good idea to use this approach for you daily developer work (especially if you using Maven central as remote Maven repository).

You can also play around with various versions of Maven by changing the image tag so at the end you can be really sure, that you project will build everywhere. Please refer to the [Docker Hub page][2] for details. 

[1]:	https://registry.hub.docker.com/_/maven/
[2]:	https://registry.hub.docker.com/_/maven/