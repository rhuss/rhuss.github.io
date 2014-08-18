---
layout: post
title: Jolokia and CORS
---

# Jolokia and CORS

[Jolokia]()[1]() has configurable [CORS]()[2]() support so that it plays nicely together with the Browser world when it comes to cross origin requests. However, Jolokia’s CORS support is not without gotchas. This gist explains how Jolokias CORS supports works, what are the issues and how I plan to solve them. 

**tldr;** *Jolokia CORS support is configured via `jolokia-access.xml` but has issues with authenticated requests which are tackled for the next release 1.3.0*

## CORS Primer

[CORS]()[3]() (Cross Origin Resource Sharing) is a specification for browsers to allow controlled access for JavaScript code to locations which are different than the origin of the JavaScript code itself. 

In simple cases, it works more or less like this:

* A JavaScript code (coming from the original location *http://a.com*) requests HTTP access via `XMLHttpRequest` to *http://b.com*
* Since the the origin of the script and target URL of the request differs, the browser adds some extract checking on the response of this request.
* The request to *b.com* contains a header `Origin: http://a.com`. 
* The server at *b.com* answering the request has to decided upon this header whether it wants allow this request. The server decision is contained in the response header `Access-Control-Allow-Origin`
* The value of this header can be either a literal URL (e.g. *http://a.com*) or a wildcard like in `Access-Control-Allow-Origin: *` which allows access from any original location.
* The browser finally decides whether it returns the response to the JavaScript based on the returned access control header. If not, is throws an exception before handing out the response data.

This is it for *simple requests*. A simple request has the following characteristics:

* HTTP method is either `GET`,`HEAD` or `POST`
* The request contains only the following headers
	* `Accept`
	* `Accept-Language` or `Content-Language`
	* `Content-Type` with the value `application/x-www-form-urlencoded`, `multipart/form-data` or `text/plain`

If this criteria are not match for a request (e.g. because it uses a different method or additional headers), a so called [preflight request]()[4]() is sent to the server before the actual request is performed. The preflight is an HTTP request with method `OPTIONS` and contains the headers `Origin` (*http://a.com* in our case), `Access-Control-Request-Method` for the HTTP method requested and `Access-Control-Request-Headers` with a comma separated list of additional header names. The server in turn answers with the allowed request methods and headers, whether an authenticated request is allowed and how long the client might cache this answer. An important point is, that a preflight request [must not be authenticated]()[5](). 

And in fact, browsers never sent an authentication header with the preflight request even when already authenticated against the target server. More on this later.

## Jolokia CORS Support

By default, Jolokia allows any CORS request. For the preflight the agent answers with
 
Access-Control-Allow-Origin: http://a.com
Access-Control-Allow-Headers: accept, authorization, content-type

The allowed headers returned are exactly the same headers as requested. For the real request with an origin header `Origin: http://a.com` the answer is

Access-Control-Allow-Origin: http://a.com
Access-Control-Allow-Credentials: true

For best computability Jolokia always answers with the provided `Origin:` which is extracted from the request (except when the origin is `null` in which case the wildcard `*` is returned. 

This behavior can be tuned by adapting the `jolokia-access.xml` policy as described in the [reference manual]()[6]() :

````xml
	<cors>
	   <allow-origin>http://www.jolokia.org</allow-origin>
	   <allow-origin>*://*.jmx4perl.org</allow-origin>
	   
	   <strict-checking/>
	</cors>
````

If a `<cors>` section is present in `jolokia-access.xml` then only those hosts declared in this sections are allowed. The Origin URLs to match against can be specified either literally or as pattern containing the wildcard `*`.  The optional declaration `<strict-checking/>` is not really connected to CORS but helps in defending against [Cross-Site-Request-Forgery]()[7]()(CSRF). If this option is given, then the given patterns are used for **every** request to compare it against the `Origin:` or `Referer:` header (not only for CORS requests).
 
## CORS and Authentication

Since `Authorization:` is for CORS not a *simple* header, when authentication is used, preflight checking is always applied. However, there is often a [catch 22]()[8]():

* The preflight check using the `OPTIONS` HTTP Method **must not be authenticated** as explained above, so browser doesn’t send the appropriate authentication headers when doing the preflight.
* The Jolokia agent is typically secured completely no matter which HTTP method is used. 
* The preflight check fails, the request fails. 

The only clean solution is to setup Jolokia Authentication that way that `OPTIONS` request are not secured. 

Let’s have a look at the individual Agents:

### JVM Agent

Since the JVM agent does all the security stuff on its own, it is not a big deal to introduce this specific behavior. Next one.

### WAR Agent

The WAR agent use authentication and authorization as defined in the [Servlet Specification]()[9](), i.e. the appropriate `<security-constraint>` must be added manually to the web.xml ([jolokia]()[10]() is  a CLI tool which helps in this repackaging). Unfortunately there is no way to secure the same `<url-pattern>` differently for different HTTP Methods (i.e. secured with an `<auth-constraint>` for `GET` and `POST`, but accessible for everybody for `OPTIONS`). I tried hard by providing multiple `<security-constraint>` but failed miserably (if you know how to this, please let me know).

The only solution is to switch over to checking a given role on our own without relying on the declarative JEE security mechanism. Since we can check the role programmatically (`HttpServletRequest.isUserInRole()`) this should not be that big deal. But it’s still some work ….

### OSGi Agent

When using an [OSGI HttpService]()[11]() adding this behavior should not be difficult since security is handled programmatically here as well (`HttpContext.handleSecurity()`)

### Other Agent variants

This is the dark matter, because I don’t know where and how Jolokia is integrated directly into a bigger context. I know that [ActiveMQ]()[12](), [Karaf]()[13]() and [Spring Boot]()[14]() uses Jolokia internally. In order to support authenticated CORS access they probably needs to be changed to allow unauthorized `OPTIONS` access for everybody. Since this is not under my control I have no idea when and even whether it ever will happen. Generic purpose console like [hawt.io]()[15]() rely in some setups on CORS access so it would be real cool if we can get it out there. Help with this is highly appreciated ;-)

## Roadmap

Since 1.2.2 is already finished and about to be published today, the stuff I can do as described above will go into a 1.3.0. Looking back at my release history this will probably be ready approx. end of august or september.


[1](): http://www.jolokia.org
[2](): http://www.w3.org/TR/cors/
[3](): http://www.w3.org/TR/cors/
[4](): http://www.w3.org/TR/cors/#resource-preflight-requests
[5](): http://www.w3.org/TR/cors/#cross-origin-request-with-preflight-0
[6](): http://www.jolokia.org/reference/html/security.html#security-policy
[7](): http://de.wikipedia.org/wiki/Cross-Site-Request-Forgery
[8](): https://code.google.com/p/twitter-api/issues/detail?id=2273
[9](): https://jcp.org/aboutJava/communityprocess/final/jsr315/
[10](): http://search.cpan.org/roland/jmx4perl/scripts/jolokia
[11](): http://www.osgi.org/javadoc/r4v42/org/osgi/service/http/HttpService.html
[12](): http://activemq.apache.org/rest.html
[13](): http://karaf.apache.org/manual/latest/users-guide/monitoring.html
[14](): https://github.com/spring-projects/spring-boot/blob/master/spring-boot-docs/src/main/asciidoc/production-ready-features.adoc
[15](): http://hawt.io


