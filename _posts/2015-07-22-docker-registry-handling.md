---
layout: post
title: Docker registry name handling is a mess
published: false
---

Putting the registry location, which is meta data, into the image name, which is often used like an identifier, is asking for trouble. 

<!-- more -->

Your carefully crafted Docker images will land in a Docker registry eventually. This can be either the public Docker registry called **Docker Hub**  or a private registry. How do you specify a registry when doing a `docker push` ? Well, the registry is part of the unique image name (or better 'repository name' but I will use image as synonym in the following). And that is where all the trouble starts.

An image has an unique id, which is a hash. It can also have a name. However, this is not a 1:1 relation: An image can have multiple names. Within a host the name is often used as an identity (e.g.  you create and start containers typically from image names). A registry however is some sort of metadata specifying where to put an image. The same image can be pushed to different registries. But for this two work it needs two different names. 

So in order to push to a dedicated registry which is not (and should not be) part of the name one has to do the following:

* Create a new name with the registry: `docker tag myname registry/myname`
* Push it: `docker push registry/myname`
* Remove the temporary name again: `docker rmi registry/myname`

The [rhuss/docker-maven-plugin][1] takes these extra step when a registry is specified like in `mvn docker:push -Ddocker.registry=...`. 
This is not only cumbersome but also needs some extra fences to ensure that these three steps are done transactional. 

Wouldn't it be so much easier if a registry would be really handled as what it is, *meta data* ? And that `docker push` would support a `--registry` flag ? I'm pretty sure there is some reason why not, however I couldn't find that.

The next thing is, that there are multiple ways how to specify the default registry, which also causes pain. Docker Hub is known as `index.docker.io`, `docker.io` and `registry.hub.docker.com` (the former name which still seems to work). You can also define you default registry during startup of the Docker daemon. 

Unfortunately, Docker daemons treat the default registry quite differently. Some strip off a given default registry from the name when creating the build, other, like the Fedora/CentOS variant add a `docker.io/` prefix if no name is given. `registry.hub.docker.com` in contrast is used as 'normal' registry (so the name stays prefixed). However when you push to it you'll end up at Docker Hub, too.

That's all confusing. Dealing with all these different behaviours is one of the biggest challenges when maintaining Docker tools like the [docker-maven-plugin][2].

[1]:	https://github.com/rhuss/docker-maven-plugin
[2]:	https://github.com/rhuss/docker-maven-plugin