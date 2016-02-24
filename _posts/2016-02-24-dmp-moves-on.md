---
layout: post
title: docker-maven-plugin moves on
published: true
---
**rhuss/docker-maven-plugin** is dead, long live **fabric8/docker-maven-plugin** !
<!-- more -->

If you follow the Docker Maven Plugin Scene[^1], you probably noticed that there has been quite some progress in the last year. Started as a personal research experiment early 2014, [rhuss/docker-maven-plugin][1] (d-m-p) has took off a little bit. With more than 300 GitHub stars it's now the second most popular docker-maven-plugin. With 38 contributors we were able to do 36 releases. It is really fantastic to see that many people contributing to a rather niche product. Many kudos go out to [Jae][2] for his many contributions and continued support on fixing and answering issues. Thanks also for always being very patient with my sometimes quite opinionated and picky code reviews :)

However it is now time to ignite the next stage and bring this personal 'pet' project to a wider context. And what is better suited here than the fabric8 community ? 

[Fabric8][3] is a next generation DevOps and integration platform for Docker based applications, with a focus on [Kubernetes][4] and [OpenShift][5] as orchestration and build infrastructure. Its a collection of multiple interrelated projects including Maven tooling for interacting with Kubernetes and OpenShift. d-m-p is already included as foundation for creating Docker application images.

I'm very happy that d-m-p has now found its place in this ecosystem where it will continue to flourish even faster. 

The [fabric8 community][6] is very open and has established multiple communications channels on which you will find d-m-p now, too:

* `#fabric8` on `irc.freenode.net` is an IRC channel with a lot of helpful hands (including myself)
* A [mailing list][7] for more in depth discussions
* Issues are still tracked with [GitHub issues][8]
* d-m-p specific blog posts will go out on the [fabric8 blog][9] in the future.
	 
So, what changed ?

* `rhuss/docker-maven-plugin` has been transferred to [fabric8io/docker-maven-plugin][10]
* The Maven group id has changed from `org.jolokia` to `io.fabric8` for all releases 0.14.0 and later. 
* CI and release management will be done on the fabric8 platform. 

And what will **not** change ?

* d-m-p will always be usable with plain Docker, speaking either to a remote or local Docker daemon. No Kubernetes, no OpenShift required.
* I'll continue to work on d-m-p ;-)

Thanks so much for all the fruitful feedback and pull requests. Keep on rocking ;-)


[^1]:	with more than 15  `docker-maven-plugin`s its probably fair to call it a "scene" ;-)

[1]:	https://github.com/fabric8io/docker-maven-plugin
[2]:	https://github.com/jgangemi
[3]:	http://fabric8.io
[4]:	http://kubernetes.io/
[5]:	https://www.openshift.com/
[6]:	http://fabric8.io/community/index.html
[7]:	https://groups.google.com/forum/#!forum/fabric8
[8]:	https://github.com/fabric8io/docker-maven-plugin/issues
[9]:	https://blog.fabric8.io/
[10]:	https://github.com/fabric8io/docker-maven-plugin