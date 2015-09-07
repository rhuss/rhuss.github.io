---
layout: post
title: fish-pepper - Docker on Capsaicin
published: true
---

When I had to create create multiple Docker base images which only differ slightly for some minor variations I couldn't avoid to feel quite dirty because of all the copying & pasting of Dockerfile fragments. We all know that this smells, but unfortunately Docker has only an answer for *inheritance* but not for *composition* of Docker images. Luckily there is now [fish-pepper][1], a multidimensional docker build generator, which steps into the breach in the meantime.

<!-- more -->

`fish-pepper` allows you to create many similar Docker builds with templates and building blocks which allows for *compositions* of Dockerfiles.

For example consider a **Java base image**: Some users might require Java 7, some want Java 8. For running Microservices a JRE might be sufficient. In other use cases you need a full JDK. These four variants are all quite similar with respect to documentation, Dockerfiles and support files like startup scripts.  Copy-and-paste might seem to work for the initial setup but there are severe drawbacks considering image evolution or introduction of even more parameters.

With `fish-pepper` you can use flexible templates which are filled with variations of the base image (like `'version' : ['java7', 'java8'], 'type': ['jdk', 'jre']`) and which will create multiple, similar Dockerfile builds. 

The main configuration of an image family is a YAML file `images.yml` which defines the possible parameters. For the example above it is

```
fish-pepper:
  params:
    - "version"
    - "type"
```

The possible values for these parameters are given in a dedicated `config` section:

```
config:
  version:
    openjdk7:
      java: "java:7u79"
      fullVersion: "OpenJDK 1.7.0_79"
    openjdk8:
      java: "java:8u45"
      fullVersion: "OpenJDK 1.8.0_45"
  type:
    jre:
      extension: "-jre"
    jdk:
      extension: "-jdk"
```

Given this configuration, four builds will be generated when calling `fish-pepper`, one for each combination of *version* (openjdk7,openjdk8) and *type* (jre,idk) parameter values. 

These value can now be filled into templates which are stored in a `templates/` directory. The `Dockerfile` in this directory can refer to this configuration through a context object `fp`:

```
FROM {{ "{{= fp.config.version.java + fp.config.type.extension " }}}}
.....
```

Templates uses [DoT.js][2] as template engine, so that the full expressiveness of JavaScript can be used. The fish-pepper [context object][3] `fp` holds the configuration and more.

The given configuration will lead to four Docker build directories:

```
images/
  +---- openjdk7
  |        +--- jre -- Dockerfile, ...
  |        +--- jdk -- Dockerfile, ...
  |
  +---- opendjk8
           +--- jre -- Dockerfile, ...
           +--- jdk -- Dockerfile, ...
```

The generated build files can also be used directly to create the images with `fish-pepper build`. This will reach out to a Docker daemon and create the images `java-openjdk7-jre`, `java-openjdk7-jdk`, `java-openjdk8-jre` and  `java-openjdk8-jdk`.

Alternatively these builds can be used as the content for automated Docker Hub builds when checked into Github. The full example can be found on [GitHub][4].

But wait, there is more:

* [Blocks][5] can be used to reuse Dockerfile snippets and files to include across images. Blocks can be stored locally or referenced via a remote Git repository. Examples for blocks are generic [startup scripts][6] or other value add functionality like enabling agents like [agent bond][7].
* Flexible [file mapping][8] allow multiple alternative templates.
* [Defaults][9] allow shared configuration between multiple parameter values.
	 
fish-pepper can be seen in its fully beauty in [fabric8io/base-images][10] where more than twenty five base images are maintained with fish-pepper. 

If you have node.js installed you can install it super easy with 

    npm -g install fish-pepper

In the following blogs I will show more usage examples, especially how "blocks" can be easily reused and shared. 

[1]:	https://github.com/fabric8io/fish-pepper
[2]:	http://olado.github.io/doT/index.html
[3]:	https://github.com/fabric8io/fish-pepper#template-context
[4]:	https://github.com/fabric8io/fish-pepper/tree/master/example
[5]:	https://github.com/fabric8io/fish-pepper#blocks
[6]:	https://github.com/fabric8io/run-java-sh/tree/master/fish-pepper/run-java-sh
[7]:	https://github.com/fabric8io/agent-bond/tree/master/fish-pepper/agent-bond
[8]:	https://github.com/fabric8io/fish-pepper#file-mappings
[9]:	https://github.com/fabric8io/fish-pepper#defaults
[10]:	https://github.com/fabric8io/base-images
