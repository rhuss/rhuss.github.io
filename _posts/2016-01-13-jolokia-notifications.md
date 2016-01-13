---
layout: post
title: Jolokia 2.0 - JMX Notifications
published: true
---
This screencast gives a live demo of the forthcoming JMX notification support in Jolokia 2.0.
<!-- more -->

<iframe src="https://player.vimeo.com/video/151629488" width="720" height="405" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

Jolokia supports currently two notification modes. In all modes, the Jolokia agent itself subscribe to a JMX notification locally and then dispatches the notifications to its clients.

* **Pull Mode** : Here, the agent keeps the notification received for a client in memory and sends it back on an JMX request to a Jolokia specific MBean. A client typically queries this notification MBean periodically.
* **SSE Mode** : [Server Sent Events][1] are a W3C standard for pushing events from an HTTP server to a client. With this mode the Jolokia agents directly pushes any notification it receives to the client. The advantage is of course a much lower latency compared to the pull mode, but SSE is [not available for Internet Explorer][2], including 11. What a pity. 

The [Jolokia protocol][3] has been extended with the top level action `notification` and subcommands.

* `register` / `unregister` : Register / unregister a  notification client
* `add` / `remove` : Add / remove a listener subscription
* `list` : list all subscriptions for a client
* `ping` : Keep subscription alive
* `open` : Use for creating a back channel. E.g. the *SSE* mode keeps this GET request for pushing back an event stream. 

Currently only the new Jolokia JavaScript client supports JMX notification. If you are interested in having it in other clients (e.g. Java), too, please let me know. I would be more than happy for coders jumping on the Jolokia bandwagon since there is still quite some stuff to do for 2.0.

The source code to this demo and the new Jolokia JavaScript client is on GitHub: [https://github.com/jolokia-org/jolokia-client-javascript][4].



[1]:	http://www.w3.org/TR/2011/WD-eventsource-20110208/
[2]:	http://caniuse.com/#feat=eventsource
[3]:	https://jolokia.org/reference/html/protocol.html
[4]:	https://github.com/jolokia-org/jolokia-client-javascript "https://github.com/jolokia-org/jolokia-client-javascript"