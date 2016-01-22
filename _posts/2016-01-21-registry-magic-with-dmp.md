---
layout: post
title: Registry Magic with docker-maven-plugin
published: true
---
Dealing with multiple Docker registries is hard, mostly because the meta information where a image is located is part of a Docker image's name, which is typically used as an identifier, too.

Let's see how the [rhuss/docker-maven-plugin][1] deals with this peculiarity.
<!-- more -->

When setting up a Maven build for creating Docker images out of your Java application, the classical way to specify the registry where to push the final Docker image is to bake it into the image's name. The drawback however is that you couple your build to this particular registry so that it is not possible to push your image to another registry when building the image.  

### Pull and Push

The [docker-maven-plugin][2] (`d-m-p` in short) interacts[^1] with Docker registries in two use cases: 

* **Pulling** base images from a registry when building images with `docker:build` or starting images with `docker:start`
* **Pushing** built images to a registry with `docker:push`

In both cases you can define your build agnostic from any registry by omitting the registry part in your image names[^2] and specify it externally as meta information. This can be done in various ways:

* Adding it to the plugin configuration as an `<registry>` element. This can be easily put into a Maven profile (either directly in the `pom.xml` or also in `~/.m2/settings.xml`). 
* Using a system property `docker.registry` when running Maven
* As a final fallback an environment variable `DOCKER_REGISTRY` can be used, too.

For example, 

{% highlight bash %}  
mvn -Ddocker.registry=myregistry.domain.com:5000 docker:push
{% endhighlight %}

When you combine build and push steps in a single call like in 

{% highlight bash %}  
mvn package docker:build docker:push
{% endhighlight %}

a pull operation for a base image and a push operation can happen. To allow different registries in this situation the properties `docker.pull.registry`  and `docker.push.registry` are supported, too, (with the corresponding configuration elements `<pullRegistry>` and `<pushRegistry>`, respectively).

When pushing an image this way, the following happens behind the scene (assuming an image named `user/myimage` and target registry `myregistry:5000`)

* The image `user/myimage` is tagged temporarily as `myregistry:5000/user/myimage` in the Docker daemon.
* The image `myregistry:5000/user/myimage` is pushed.
* The tag is removed again.

### Authentication

That's all fine, but how does d-m-p deal with authentication ? Again, there are several possibilities how authentication can be performed against a registry:

* Using a `<authConfig>` section in the plugin configuration with`<username>` and `<password>` elements. 
* Providing system properties `docker.username` and `docker.password` when running Maven
* Using a `<server>` configuration in `~/.m2/settings.xml` with possible encrypted password. That's the most maven-ish way for doing authentication.
* Login into the registry with `docker login`. The plugin will pick up the credentials from `~/.docker/config.json`

There are again variants to distinguish between authentication for pulling and pushing images to registries (e.g. `docker.push.username` and `docker.push.password`). All the details can be found in the [reference manual][3].

### Using the OpenShift Registry

[OpenShift][4] is an awesome PaaS platform on top of [Kubernetes][5]. It comes with an [own Docker registry][6] which can be used by d-m-p, too. However, there are some things to watch out for. 

First of all, the registry needs to be exposed to the outside so that a Docker daemon outside the OpenShift cluster can talk with the registry:

{% highlight bash %}  
oc expose service/docker-registry --hostname=docker-registry.mydomain.com
{% endhighlight %}

The hostname provided should be resolved by your host to the OpenShift API server's IP (this happens automatically if you use the [fabric8 OpenShift Vagrant image][7] for a one-node developer installation of OpenShift).

Next, it is important to know, that the OpenShift registry use the regular OpenShift SSO authentication, so you have to login into OpenShift before you can push to the registry. The access token obtained from the login is then used as the password for accessing the registry:

{% highlight bash %}  
# Login to OpenShift. Credentials are stored in ~/.kube/config.json:
oc login

# Use user and access token for authentication:
mvn docker:push -Ddocker.registry=docker-registry.mydomain.com \
	           -Ddocker.username=$(oc whoami) \
	           -Ddocker.password=$(oc whoami -t)
{% endhighlight %}

The last step can be simplified by using `-Ddocker.useOpenShiftAuth` which does the user and token lookup transparently.

{% highlight bash %}  
mvn docker:push -Ddocker.registry=docker-registry.mydomain.com \
                -Ddocker.useOpenShiftAuth
{% endhighlight %}

The configuration option `useOpenShiftAuth` again comes in multiple flavours: a default one, and dedicated for push and pull operations (`docker.pull.useOpenShiftAuth` and `docker.push.useOpenShiftAuth`).

### tl;dr

Among all the [many docker maven plugins][8], [rhuss/docker-maven-plugin][9] provides the most flexible options for accessing Docker registries and authentication. The gory details can be found in the [reference manual][10] which documents [registry handling][11] and [authentication][12] in detail.

[^1]:	The interaction is always indirectly via the Docker daemon, since a Docker client like d-m-p only talks with the Docker daemon directly.

[^2]:	Of course you can the registry part in your image names in which case this registry has always the highest priority.

[1]:	https://github.com/rhuss/docker-maven-plugin
[2]:	https://github.com/rhuss/docker-maven-plugin
[3]:	http://ro14nd.de/docker-maven-plugin/authentication.html
[4]:	https://www.openshift.com/
[5]:	http://kubernetes.io/
[6]:	https://docs.openshift.com/enterprise/latest/install_config/install/docker_registry.html
[7]:	http://fabric8.io/guide/getStarted/vagrant.html
[8]:	https://github.com/search?utf8=%E2%9C%93&q=docker-maven-plugin
[9]:	https://github.com/rhuss/docker-maven-plugin
[10]:	http://ro14nd.de/docker-maven-plugin/
[11]:	http://ro14nd.de/docker-maven-plugin/
[12]:	http://ro14nd.de/docker-maven-plugin/authentication.html
