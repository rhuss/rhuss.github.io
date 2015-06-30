---
layout: post
title: docker:watch
---

Ok, you know Docker. And since you are a Java developer you want to know how you can use this in your daily development workflow. You probably also heard about *the* [docker-maven-plugin][1] which seamlessly creates Docker images, starts and stops Docker containers and more all with a concise configuration syntax. 

And now there is this new goal `docker:watch`.
<!-- more -->

We developers are lazy, right ? We want our code to compile fast, we want the servers to start up fast. And we want to test changes quickly. That's why we love [OSGi][2] and [JRebel][3]. And we want this for Docker containers, too. 

Good news. [docker-maven-plugin][4] will support hot rebuild of Docker images and hot restart of containers with a new Maven goal `docker:watch`. It will be released with version 0.12.1. For the brave coder 0.12.1-SNAPSHOT is already out there, the documentation can be found [here][5].

But before losing more words, here's a live sneak preview.

<iframe src="https://player.vimeo.com/video/132183699" width="720" height="405" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>


[1]:	https://github.com/rhuss/docker-maven-plugin
[2]:	http://www.osgi.org/Main/HomePage
[3]:	http://zeroturnaround.com/software/jrebel/
[4]:	https://github.com/rhuss/docker-maven-plugin
[5]:	https://github.com/rhuss/docker-maven-plugin/blob/integration/doc/manual.md#dockerwatch