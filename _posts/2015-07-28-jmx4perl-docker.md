---
layout: post
title: Jmx4Perl for everyone
---

As you might know, [Jmx4Perl][1] is the mother of [Jolokia][2]. But what might be not so known is, that Jmx4Perl provides a set of nice CLI tools for accessing Jolokia agents. However, installing Jmx4Perl manually is cumbersome because of its many Perl and also native dependencies. 

However, if you are a Docker user there is now a super easy way to benefit from this gems.
<!-- more -->

Even if Perl is not your cup of tea, you might like the following tool (for which of course no Perl knowledge is required at all): 

* [**jmx4perl**][3] is a command line tool for one-shot querying Jolokia agents. It is perfectly suited for shell scripts.
* [**j4psh**][4] is a readline based, JMX shell with coloring and command line completion. You can navigate the JMX namespace like directories with `cd` and `ls`, read JMX attributes with `cat` and execute operations with `exec`.
* [**jolokia**][5] is an agent management tool which helps you in downloading Jolokia agents of various types (war, jvm, osgi, mule) and versions. It also knows how to repackage agents e.g. for enabling security for the war agent by in-place modification of the web.xml descriptor. 
* [**check\_jmx4perl**][6] is a full featured Nagios plugin.

How can you now use these tools ? All you need is a running Docker installation. The tools mentioned above are all included within the Docker image [jolokia/jmx4perl][7] which is available from Docker Hub. 

Some examples:

```
# Get some basic information of the server
docker run --rm -it jolokia/jmx4perl \
       jmx4perl http://localhost:8080/jolokia

# Download the current jolokia.war agent
docker run --rm -it -v `pwd`:/jolokia jolokia/jmx4perl \
       jolokia

# Start an interactive JMX shell
# server "tomcat" is defined in ~/.j4p/jmx4perl.config
docker run --rm -it -v ~/.j4p:/root/.j4p jolokia/jmx4perl \
       j4psh tomcat
```

In these examples we mounted some volumes:

* If you put your server definitions into `~/.j4p/jmx4perl.config` you can use them by mounting this directory as volume with `-v ~/.j4p:/root/.j4p`. 
* For the management tool `jolokia` it is recommended to mount the local directory with `-v $(pwd):/jolokia` so that downloaded artefacts are stored in the current host directory. (Note for boot2docker users: This works only when you are in a directory below you home directory)

It is recommended to use aliases as abbreviations:

```
alias jmx4perl="docker run --rm -it -v ~/.j4p:/root/.j4p jolokia/jmx4perl jmx4perl"
alias jolokia="docker run --rm -it -v `pwd`:/jolokia jolokia/jmx4perl jolokia"
alias j4psh="docker run --rm -it -v ~/.j4p:/root/.j4p jolokia/jmx4perl j4psh"
```

As an additional benefit of using Jmx4Perl that way, you can access servers which are not directly reachable by you. The Jolokia agent must be reachable by the Docker daemon only. For example, you can communicate with a SSL secured Docker daemon running in a DMZ only. From there you can easily reach any other server with a Jolokia agent installed, so there is no need to open access to all servers from your local host directly. 

Finally, here's a short appetiser with an (older) demo showing `j4psh` in action.

<iframe width="720" height="405" src="https://www.youtube.com/embed/y9TuGzxD2To" frameborder="0" allowfullscreen></iframe>

[1]:	http://www.jmx4perl.org
[2]:	https://jolokia.org/
[3]:	http://search.cpan.org/~roland/jmx4perl/scripts/jmx4perl
[4]:	http://search.cpan.org/~roland/jmx4perl/scripts/j4psh
[5]:	http://search.cpan.org/~roland/jmx4perl/scripts/jolokia
[6]:	http://search.cpan.org/~roland/jmx4perl/scripts/check_jmx4perl
[7]:	https://registry.hub.docker.com/u/jolokia/jmx4perl/