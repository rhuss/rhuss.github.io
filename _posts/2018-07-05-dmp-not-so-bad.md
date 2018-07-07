---
layout: post
title: docker-maven-plugin might be still useful
---
Yesterday a blog post [Using Docker from Maven and Maven from Docker][post] by [Kostis Kapelonis][kostis] was published which gives some insights on the possible relationships between Docker and Maven.
The article makes some essential points really, and gives an overview for the two remaining Docker Maven plugins as well as how [Codefresh](https://codefresh.io/) recommends doing Docker multi-stage builds as the alternative.
As I'm the maintainer of the [fabric8io/docker-maven-plugin][dmp], I'd like to comment on this matter.

I already commented on the original blog post (thanks for approving the comment), but I'm happy to repeat my arguments
here again.
<!-- more -->

The [article][post] ditches two docker-maven-plugins before it promotes Docker multi-stage builds for some reasons.

To be honest, I think both approaches have their benefits, but let me comment first on two arguments given concerning the [fabric8io/docker-maven-plugin][dmp-git].

> There have been cases in the past where Docker has broken compatibility even between its client and server, so a Maven plugin that uses the same API will instantly break as well.

This compatibility issue might be right especially if you use a typed approach to access the Docker REST API which is used by various Docker client libraries. As explained in the post, fabric8 d-m-p accesses the Docker daemon directly without any client library and with not marshalling. This is because it accesses only the parts required for the plugin's feature set, which also means that json responses are handled in a very defensive and untyped way.

And yes, there was one issue in the early days in 2014 with a backwards-incompatible API change from Docker. This issue could be fixed quite quickly because d-m-p hadn't to wait for a client library to be updated. However, since then there never has been an issue and for the core functionality that d-m-p uses.

I think the relevance of Docker API incompatibilities is exaggerated in this blog post.

> Hopefully, the fabric8 plugin also supports plain Dockerfiles. Even there, however, it has some strong opinions. It assumes that the Dockerfile of a project is in src/main/docker and also it uses the assembly syntax for actually deciding what artefact is available during the Docker build step.

That is simply not true. You can just put a Dockerfile on the same level as the pom.xml, refer to your artefacts in the `target/` directory (with Maven property substitution), and then declare the plugin *without any configuration*.
See my [other blog post](https://ro14nd.de/simple-dockerfile-mode-dmp) for a short description of how it works.

BTW, the reason for the own XML syntax is a historical one. The plugin started in 2014 when Dockerfile was entirely unknown to Java developers. But Maven plugin XML configuration was (and still is) a well-known business. As time passed by and Docker become more and more popular for Java developers, the `Dockerfile` syntax is well known now these days, too. So, I completely agree, that you should use Dockerfiles if possible, and that's why the plugin supports Dockerfiles as a first-class citizen since the recent versions. The next step is to add similar support for `docker-compose.yml` files for running containers. There is already docker compose support included, albeit a bit hidden.

-----

I agree that multi-stage Docker builds are fantastic for generating reproducible builds, as the build tool (Maven) is used in a well-defined version. However, using a locally installed Maven during development has advantages, too. E.g. the local Maven repository avoids downloading artefacts over and over again, resulting in much faster build times and turnaround times. Of course, you can add caching to the mix for multi-stage builds, but then the setup gets more and more involved. Compare this to using a d-m-p for which you don't even need a local Docker CLI installed, and you can 'just start'. For CI builds this properly doesn't matter much though (and that's what the blog post is all about I guess).

Other advantages of using fabric8's d-m-p :

* Running all your containers (app + deps) locally without the need of support from a CI system. As a side note, the custom compose-like syntax of codefresh's CI is not so much different to the custom configuration syntax of fabric8's d-m-p. It's custom.
* Extended authentication support against various registries (Amazon ECR, Google GCR, ...)
* Automatic rebuilds during development with `docker:watch` which increase turnaround times tremendously
* Download support files (e.g. startup scripts) automatically by just declaring a dependency in the plugin (blog post pending)
* .... and even more stuff.

In the end, your mileage may vary, but having an article conclusion without really trying to compare pros and cons of both approaches is far too biased for me.

**Update: Kostis replied to my comment, and an interesting discussion is going over [there][post-comment]**

[post]: https://codefresh.io/howtos/using-docker-maven-maven-docker/
[kostis]: https://twitter.com/codepipes
[dmp]: https://dmp.fabric8.io/
[dmp-git]: https://github.com/fabric8io/docker-maven-plugin
[post-comment]: https://codefresh.io/howtos/using-docker-maven-maven-docker/#comment-159
