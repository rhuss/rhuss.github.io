---
layout: post
title: Why Jolokia is not RESTful
published: true
---

From time to time people come to me and say: "I really would love Jolokia if only it would be RESTful". This post tells you why.
<!-- more -->

I really like REST, yes I do. 
If I would crete a new application on a green field, its remote access API would very likely obey the REST paradigm.[^1] 

However, [Jolokia][1] is a different beast. 
It is a bridge to the world of JMX, providing an open minded alternative to the rusty and Java specific JSR-160 standard. 
Its protocol is based on JSON over HTTP, so in principle it could be REST. 
But it is not, mainly for the following two reasons:

### JMX resource naming is a mess

Jolokia doesn't not have any influence on the naming of the resources it accesses. 
These resources are JMX [MBeans][2] and their identifiers are [ObjectNames][3]. 
ObjectNames have a certain structure but beside this they can be named arbitrarily. 
So if you want to provide an HTTP API for accessing these repositories, this free form addressing poses some challenges, especially for read operations with `GET`. 
For example it is impossible to transmit a slash (`/`) or backslash (`\\`) as part of an URL's path info. 
The reason is [security related][4], and each application server handles this differently: Tomcat for example completely rejects such requests whereas Wildfly / Undertow [refuses][5] to URL decode `%2F` (for `/`) and `%5C` for `\\`. 
Jetty doesn't care much. 
So in order to address a JMX MBean which contains these characters as part of their names, the typical encoding as part of an URL path doesn't work. 
One could use query parameters for this kind of addressing and in fact, Jolokia [supports][6] this, too. 
But it's still ugly. 
Also, implementers of MBeans tend to put semantic information into the MBean name like the port of a connector or the name of a database scheme.
It can't excluded that the MBean name alone can carry sensitive information.
However GET urls are *not* secured via the transport protocol and tend to end up in log files. 
So, its much safer to send these requests via POST, even when only performing read operations on JMX attributes. 

### Bulk requests

A special feature of Jolokia are [Bulk Requests][7]. 
This allows a very efficient monitoring of multiple values with a single HTTP request. 
It works by sending a list of individual, JSON encoded Jolokia requests with a single HTTP `POST` request. 
That list can contain any valid Jolokia operation: 
Reading and writing attributes, executing some operations, searching for or listing of MBeans. 
The heterogenous nature of this kind of requests makes it hard to map them to one single HTTP verb as REST suggests. 
Also, the sheer length of the request parameter forbids to send a bulk request via GET as Servlet container or other application servers impose certain restrictions on the length of an URL, which vary however from server to server.

### Jolokia implements both

For every Jolokia operation, we play both: GET and POST [^2]. 
As an integration tool, which helps to bridge different worlds without really having control over these worlds, the focus is on maximal flexibility so that it can adapt to any environment where it is used. 
REST is only of second importance here, but if you think the issues described above can be solved in a more RESTful way, I'm more than open.


[^1]:	I've to confess that I'm really not a REST expert, so if you don't agree with my arguments, I'd kindly ask you to leave a comment or tweet me for corrections.

[^2]:	or: "Country and Western"

[1]:	https://www.jolokia.org
[2]:	https://docs.oracle.com/javase/tutorial/jmx/mbeans/
[3]:	http://docs.oracle.com/javase/8/docs/api/javax/management/ObjectName.html
[4]:	http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2007-0450
[5]:	https://issues.jboss.org/browse/UNDERTOW-879
[6]:	https://jolokia.org/reference/html/protocol.html#get-request
[7]:	https://jolokia.org/reference/html/protocol.html#post-request