---
layout: post
title: Java EE Management is dead
published: true
---

Now that some weeks has been passed we all had time to absorb the [revised Java EE 8 proposal][1] presented at Java One. As you know, some JSRs remained, some things were added and some stuff was dropped. [Java EE Management API 2.0][2], supposed to be a modern successor of JSR 77, is one of the three JSRs to be dropped.

What does this mean for the future of Java EE management and monitoring ?
<!-- more -->

First of all it's fair to state that [JSR 373][3] never really took off. Since February 2015 there were not more than [86 mails][4] on the expert group mailing list, half of them written in March 2015 during incubation. At the latest of January 2016 it was clear that JSR-373 [is not on Oracle's focus anymore][5]. To be honest, even we members of the expert group, we were not able to push this JSR further.

How did it come that far ? Let's have a look back into history. 

All starts with [JSR 3][6] back in 1999. This first JMX specification is the foundation of all Java resources management. As it can been seen by its age, Java folks took care about Management and Monitoring from the very beginning on. And even better, since [JS2E 5][7] JMX is integral part of Java SE so its available on every JVM out there.

Over the years, additional JSRs were added on top of this base:

* [JSR 160][8] defines a remote protocol for JMX,, which is based on [RMI][9]. This might have been a good decision in 2003, but turned out to be awful to use especially for non-Java based monitoring systems.
* [JSR 262][10] was started to overcome this by defined a "WebServices Connector for Java Management Extensions Agents" which was mostly around SOAP services. However although even an initial implementation existed, it was withdrawn before the final release. It's not completely clear why it was stopped in 2008 and later withdrawn, as the [public review ballot has been approved][11], although it was a tight result. The biggest objections were on dependencies on "proprietary" WS-\* specifications. 
* "J2EE Management" [JSR 77][12] was finished in 2002 and defines a hierarchy how Management and Monitoring resources exposed by a Java EE server is structured. It allows a uniform interface for how to access the various Java EE resources, like web applications or connector pools. Beside this it also defines how statistics are exposed by defining various metrics formats. However, implementing the `StatisticsProvider` model is not mandatory and from my personal experience it was implemented only rarely by some vendors and if so, not for every resource.
* [JSR 88][13] complements JSR 77 and defines a common format for deploying Java EE artefacts.
* [JSR 255][14] was started to be the next version of JMX and supposed to be included in Java 7. Although it was already nearly finished and integrated, [it didn't make it into Java 7][15] (nor Java 8). The spec was then dormant until it was finally withdrawn in 2016.

With the dead of JMX 2.0 in 2009 the evolution of JMX as a standard for Java SE has stalled. But what's about Java EE Management ? At least JSR 77 is still part of Java EE 7 and for Java EE 8 the successor was supposed to be JSR 373. JSR 373 tackles the problem of remote access, whereas JSR 77 still relies on RMI as a standard implementation protocol as defined in JSR 160. 

The two major goals of JSR 373 were:

* Provide an update of the hierarchal resource and statistics structure as defined by JSR 77
* Provide a REST access to these resources independent of JMX

In the often cited [Java EE 8 Community Survey][16] more than 60% were in favour of defining a new API for managing application, which should be based on REST (83% pro-votes). This finally lead to JSR 373. However, as it seems in retrospective, a deep interest in this topic was not really given and probably lead to this final decision to drop JSR 373 from Java EE 8.

So, what is the state of Monitoring and Management of Java and in particular Java EE applications nowadays and what can be expected in the future ? Let's have a look into the crystal ball.

* **JMX is here to stay**. It is part of Java SE and I don't know of any plans for removing it from future Java editions. Ok, it feels a bit rusty but it is still rock solid and gives you deep insight in the state of your JVM. With tools like [Jolokia][17] you can overcome most of the restrictions JSR 160 imposes. (Disclaimer: since I'm the author of Jolokia all my personal opinions given here should be evaluated in this light :)
* It is not clear how the Management API of Java EE 8 and beyond looks like. It does not look like that JSR 77 will survive. Will there be a standard for Java EE management at all ? Probably not, and so there is the danger that vendors will push their proprietary management APIs, which already [happens][18] to some extent. Luckily, most of these proprietary APIs are also mirrored in JMX these days.
* On the other hand, it can be a good thing that there is no other Management API which is not based on JMX. That's because you will always need JMX to monitor the basic aspects like Heap Memory usage or Thread count, which are covered by Java SE. Adding a different, REST like protocol for Java EE monitoring requires operators to access a Java EE server with two different protocols (JMX  **and** Rest), duplicating configuration efforts on the monitoring side. This can only be avoided if the [Java EE resources are mirrored in JMX][19], too.

To sum it up, I think its a pity that management aspects, which played a prominent role over the whole evolution of Java, has dropped dramatically in interest and will be dropped completely in Java EE 8. As a replacement a new [Health Check][20] API has been announced, but to be honest, that can't be a complete replacement for classical management and monitoring where the evaluation of a system's health is done on a dedicated monitoring platform (e.g. like Nagios or Prometheus). These classical platforms take the plain metrics data exposed by the application and does the evaluation of the data on their own.
 
The good thing is still that you have JMX to the rescue and I'm pretty sure that this technology will survive also this storm, if vendors are willing to support it for exposing application server metrics, too. Even without a Java EE standard.

> Disclaimer: Of course, all the opinions expressed here are my personal ones and are not related to the JSR 373 expert group.

[1]:	https://java.net/downloads/javaee-spec/JavaEE8Update.pdf
[2]:	https://www.jcp.org/en/jsr/detail?id=373
[3]:	https://www.jcp.org/en/jsr/detail?id=373
[4]:	https://java.net/projects/javaee-mgmt/lists/jsr373-experts/archive
[5]:	https://java.net/projects/javaee-mgmt/lists/jsr373-experts/archive/2016-01/message/2
[6]:	https://jcp.org/en/jsr/detail?id=3
[7]:	http://docs.oracle.com/javase/1.5.0/docs/guide/management/index.html
[8]:	https://jcp.org/en/jsr/detail?id=160
[9]:	http://www.oracle.com/technetwork/java/javase/tech/index-jsp-136424.html
[10]:	https://jcp.org/en/jsr/detail?id=262
[11]:	https://jcp.org/en/jsr/results?id=4548
[12]:	https://jcp.org/en/jsr/detail?id=77
[13]:	https://jcp.org/en/jsr/detail?id=88
[14]:	https://jcp.org/en/jsr/detail?id=255
[15]:	https://community.oracle.com/blogs/emcmanus/2009/06/16/jsr-255-jmx-api-20-postponed
[16]:	https://java.net/downloads/javaee-spec/JavaEE8_Community_Survey_Results.pdf
[17]:	https://jolokia.org/
[18]:	https://docs.jboss.org/author/display/WFLY10/The+HTTP+management+API
[19]:	https://java.net/projects/javaee-mgmt/lists/jsr373-experts/archive/2016-06/message/1
[20]:	https://java.net/downloads/javaee-spec/JavaEE8Update.pdf