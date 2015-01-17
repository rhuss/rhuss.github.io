---
layout: post
title: Health Checks with Jolokia
published: true
---

A *health check* is a useful technique for determining the overall operational state of a system in a consolidated form. It provides some kind of internal monitoring which collects metrics, evaluates them against some thresholds and provides a unified result. Health checks are now coming to [Jolokia][1]. This post explains the strategy to include health checks into Jolokia without blowing up the agents to much.

<!-- more -->

Health checks are  different to classical monitoring solutions like Nagios, where external systems collect metrics and evaluate them against some threshold on their own.  While monitoring with Nagios was and is always possible with Jolokia (and in fact was the original motivation for creating it), intrinsic health checks were avoided for the vanilla agent up to now because of the extra complexity they introduce into the agent. One of the major design goals of Jolokia is to keep it small and focussed. 

The upcoming release 1.3.0 (scheduled for the end of this month) will introduce a simple plugin architecture into Jolokia which allows to hook into the agent's lifecycle. A so called [MBeanPlugin][2] in Jolokia also allows access to the agent configuration and to the JMX system. Currently it is supported for the WAR and JVM agent, where plugins are created via a simple class path lookup. For the OSGi agent it is planned that it will pick up plugins as OSGi services.

Having this new infrastructure in place, extra functionality like health checks can be added easily. The GitHub repository [jolokia-extra][3] was created to host various extensions to the Jolokia agent, also to keep the original agent as lean as possible. Beside the new health checks there is already an extension *jsr77* for simplifying the access to [JSR-77][4] compliant JEE Servers like WebSphere.

The new [health][5] addon in *jolokia-extra* has just been started. Currently it contains not much more as proof-of-concept with some hardcoded health checks, but it already illustrate the concept: A `MBeanPlugin` registers a certain `SampleHealthCheckMBean` during startup which exposes the health checks as JMX operations (and which can be executed as usual with Jolokia). These operations have access to JMX via the `MBeanPluginContext` and can query any MBean in the system.  

But that is only the beginning. There are still a lot of design decisions to take:

* How should health check specification look like ? Should it be done via JSON or should a more expressive DSL based e.g. on Groovy should be used ?
* How are the health check store on the agent side ?
	* Looking them up in the filesystem (from a configurable path with a sane default like `~/.jolokia_healthchecks`)
	* Baking it into the agent jar
	* Uploading it via an MBean operation (and then storing them in the filesystem as well)
* What kind of meta data should be provided so that consoles like hawt.io can dynamically create their health check views ?
* How should the parameter and return value for the health checks look like ?

If you would like to participate, the discussion about the implementation details will take place in issue [\#1][6] and the current working state is summarized in this [wiki page][7].

[1]:	http://www.jolokia.org
[2]:	https://github.com/rhuss/jolokia/blob/master/agent/core/src/main/java/org/jolokia/backend/plugin/MBeanPlugin.java
[3]:	https://github.com/rhuss/jolokia-extra
[4]:	https://jcp.org/en/jsr/detail?id=77
[5]:	https://github.com/rhuss/jolokia-extra/tree/master/addon/health
[6]:	https://github.com/rhuss/jolokia-extra/issues/1
[7]:	https://github.com/rhuss/jolokia-extra/wiki/Health-Checks