---
layout: post
title: Docker maven plugin rewrite
published: true
---

My [docker-maven-plugin][1] is undergoing a major refactoring. This post explains the motivation behind this and also what you can expect in the very near future.
The configuration syntax becomes much cleaner and implicit behavior was removed. 
<!-- more -->

Originally, I needed a *docker-maven-plugin* for a very specific use case: To test  [Jolokia][2], the HTTP-JMX bridge in all the JEE and non-JEE servers out there. This was a very manual process: Fire up the VirtualBox image with all those servers installed, start a server, deploy Jolokia, run integration tests, stop the server, start the next server .... It takes easily half a day or more to do the tests before each release. That's not the kind of QA you  are looking for, really. But with docker there is finally the opportunity to automate all this: Deploy a single application on multiple different servers while controlling the lifecycle of theses servers from within the build.

Early this year when I searched the Web, I couldn't find a good Docker build integration, so I decided to write my own [docker-maven-plugin][3] to back my use case. Today you find nearly a dozen of Maven plugins for your Docker business. However, only four plugins ([alexec][4], [wouterd][5], [spotify][6] and [rhuss][7]) are still actively maintained. A later blog post will present a detailed comparison between those four plugins (or come to my [W-JAX][8] session), but this post is about the evolution of the `rhuss` plugin.

It turned out that the plugin works quite well, people liked and starred it on GitHub. It provides also some unique features like creating Docker images from [assembly descriptors][9]. 

But I was not so happy.

The reason is, that I started from a very special, probably very uncommon use case: A single application, multiple different servers for multiples tests. A much more common scenario is to have a fixed application server brand for the application, running with multiple linked backend containers like databases. My plugin doesn't work well with running multiple containers at once. Or to state it otherwise: The plugin was not prepared for orchestration of multiple docker containers.  

Also, there was too much happening *magically* behind the scenes: When pushing a data image, it was implicitly build. When starting a container for integration test, the data container is also build before. 

Two operational modes were supported: One with images holding the server and data separately in two containers (linked via `volumes`) and one so called *merged* image, holding both, the application and server together in one image. This is perfect for creating micro services. The mode is determined only by a configuration flag (`mergeData`), but it is not really clear how many and what Docker images are created. And it was hard to document which is always a very bad smell.

So I changed the configuration syntax completely. 

It is now much more explicit and you will know merely by looking at the configuration which and how many containers will be started during integration testing and what the container with the application will look like. I don't want to go into much detail here, the post is already too long. Instead here is an example of the new syntax:

\`\`\`\`xml
<plugin>
  <groupId>org.jolokia</groupId>
  <artifactId>docker-maven-plugin</artifactId>
  <version>0.10.1</version>

  <configuration>
	  <image>
	     <name>consol/tomcat-7.0</name>
	     <run>
	       <volumes>
	         <from>jolokia/docker-jolokia-demo</from>
	       </volumes>
	       <ports>
	         <port>jolokia.port:8080</port>
	       </ports>
	       <wait>
	         <url>http://localhost:${jolokia.port}/jolokia</url>
	         <time>10000</time>
	       </wait>
	     </run>
	  </image>
	  <image>
	     <name>jolokia/docker-jolokia-demo</name>
	     <build>
	       <assemblyDescriptor>src/main/assembly.xml</assemblyDescriptor>
	     </build>
	  </image>
  </configuration>
</plugin>
\`\`\`\`

This examples creates and starts **two** containers during `docker:start`, linked together via the `volumes` directive. The **`<run>`** configuration section is used  to describe the runtime behavior for `docker:start` and `docker:stop`, and **`<build>`** is for specifying how images are build up during `docker:build`. 

Alternatively, a **single** image could be created:

\`\`\`\`xml
<plugin>
  <groupId>org.jolokia</groupId>
  <artifactId>docker-maven-plugin</artifactId>
  <version>0.10.1</version>

  <configuration>
	<images>
	  <image>
	    <name>jolokia/docker-jolokia-combined-demo</name>
	    <build>
	      <baseImage>consol/tomcat-7.0</baseImage>
	      <assemblyDescriptor>src/main/assembly.xml</assemblyDescriptor>
	    </build>
	    <run>
	      <ports>
	        <port>jolokia.port:8080</port>
	      </ports>
	      <wait>
	        <url>http://localhost:${jolokia.port}/jolokia</url>
	      </wait>
	    </run>
	  </image>
	</images>
  </configuration>
</plugin>
\`\`\`\`

Here `consol/tomcat-7.0` is used as base for the image to build and the data referenced in the assembly descriptor is copied into the image. So there is no need to volume-link them together. 

I won't repeat the old, more confusing syntax for this both use cases here, you find it in the current [online documentation][10]. 

Said all that, and since `rhuss/docker-maven-plugin` is still pre-1.0, I take the liberty to change it without much thoughts on backwards compatibility (you can easily update old configurations). The new syntax is available since `0.10.1`, the old syntax will still be used in the `0.9.x` line. Everybody is encouraged to upgrade to `0.10.x`, although the documentation still reflects the old syntax (will be fixed soon). Please refer to the [examples][11] on the `new-config` branch for more details. An upgrade path will be available soon, too.

There will be a `1.0.0` release before the end of this year.

Please let me know your feedback on the new syntax and what features you would like to see. Everything is moving before the 1.0.0 freeze. You can open an [issue][12] for any suggestion or feature request.


[1]:	https://github.com/rhuss/docker-maven-plugin
[2]:	http://www.jolokia.org
[3]:	http://github.com/rhuss/docker-maven-plugin
[4]:	https://github.com/alexec/docker-maven-plugin
[5]:	https://github.com/wouterd/docker-maven-plugin
[6]:	https://github.com/spotify/docker-maven-plugin
[7]:	https://github.com/rhuss/docker-maven-plugin
[8]:	http://jax.de/wjax2014/sessions/docker-fuer-java-entwickler
[9]:	http://maven.apache.org/plugins/maven-assembly-plugin/assembly.html
[10]:	http://github.com/rhuss/docker-maven-plugin
[11]:	https://github.com/rhuss/docker-maven-plugin/tree/new-config/samples
[12]:	http://github.com/rhuss/docker-maven-plugin/issues