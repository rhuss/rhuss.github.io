---
layout: post
title: Spicy Docker Java Images with Jolokia
---

While on the way of transforming the [Jolokia][1] integration test suite from a tedious, manual, half-a-day procedure to a full automated process I ran into and felt in love with [Docker][2]. As a byproduct a [java-jolokia][3] docker repository emerged, which can be easily used as a Java base image for enabling a Jolokia JVM agent during startup for any Java application.
<!-- more -->

These images are variants of the official [java][4] Java docker image. In order to use the Jolokia agent, a child image should call the script `jolokia_opts` (which is in the path). This will echo all relevant startup options that should be included as argument to the Java startup command.

Here is a simple example for creating a Tomcat 7 images which starts Jolokia along with Tomcat:

````
FROM jolokia/java-jolokia:7
ENV TOMCAT_VERSION 7.0.55
ENV TC apache-tomcat-${TOMCAT_VERSION}

EXPOSE 8080 8778
RUN wget http://archive.apache.org/dist/tomcat/tomcat-7/v${TOMCAT_VERSION}/bin/${TC}.tar.gz
RUN tar xzf ${TC}.tar.gz -C /opt

CMD env CATALINA_OPTS=$(jolokia_opts) /opt/${TC}/bin/catalina.sh run
````

(*Don't forget to use `$(jolokia_opts)` or with backticks, but not `${jolokia_opts}`*)

The configuration of the Jolokia agent can be influenced with various environments variables which can be given when starting the container:

* `JOLOKIA_OFF` : If set disables activation of Jolokia. By default, Jolokia is enabled. 
* `JOLOKIA_CONFIG` : If set uses this file (including path) as Jolokia JVM agent properties (as described in Jolokia's [reference manual][5]. By default this is `/opt/jolokia/jolokia.properties`. If this file exists, it will automatically be taken as configuration  
* `JOLOKIA_HOST` : Host address to bind to (Default: 0.0.0.0)
* `JOLOKIA_PORT` : Port to use (Default: 8778)
* `JOLOKIA_USER` : User for authentication. By default authentication is switched off.
* `JOLOKIA_PASSWORD` : Password for authentication. By default authentication is switched off.

So, if you start your tomcat with `docker run -e JOLOKIA_OFF` no agent will be started.

Currently this image is available from [Docker Hub][6] for the latest versions of Java 6,7 and 8, respectively, as they are provided by the official Docker [java][7] image. 

Other base images can be easily added by using the configuration and templates from a super simple node based [build system][8]. 
 
All appserver images from [ConSol/docker-appserver][9] ([Docker Hub][10]) are based now on this image, so Jolokia will always be by your side ;-)







[1]:	http://www.jolokia.org
[2]:	http://docker.io
[3]:	https://registry.hub.docker.com/u/jolokia/java-jolokia/
[4]:	https://registry.hub.docker.com/_/java
[5]:	http://www.jolokia.org/reference/html/agents.html#agents-jvm
[6]:	https://registry.hub.docker.com/u/jolokia/java-jolokia/
[7]:	https://registry.hub.docker.com/_/java/
[8]:	https://github.com/rhuss/docker-java-jolokia
[9]:	https://github.com/ConSol/docker-appserver
[10]:	https://registry.hub.docker.com/repos/consol/