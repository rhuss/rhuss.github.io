---
layout: post
title: Elegant Camel route configuration
---
I'm a big fan of the [Camel Java DSL][camel-java-dsl] for defining Camel routes with a `RouteBuilder`. This is super easy and slim. However, in this blog post I show you a nerdy trick how this can be done even more elegant.
<!-- more -->

<!--
<img src="../images/camel-logo.png" style="margin-top: 0px; margin-left: 40px; float: right"/>
-->

If you are a Camel user, you know, that defining a route for a given Camel context `ctx` ist just a matter to implement the `configure()` method of the abstract `RouteBuilder` class:

```java
ctx.add(new RouteBuilder {

   @Override
   public void configure() throws Exception {
      from("file:data/inbox?noop=true")
        .to("file:data/outbox");
   }

});
```

Its really simple and you can use the whole Camel machinery from within your `configure()` method.

However, this kind of configuration can be performed even simpler. Let's assume that you have a no-op default implementation of `RouteBuilder` called `Routes`:

```java
public class Routes extends RouteBuilder {
    @Override
    public void configure() throws Exception { }
}
```

Then, the configuration can be rewritten simply as

```java
{% raw %}ctx.add(new Routes {{
      from("file:data/inbox?noop=true")
        .to("file:data/outbox");
}});{% endraw %}
```

This trick just uses Java's [object initializers][object-initializers], a not so well known language feature. The inspiration for providing the DSL context like this comes from [JMockit][jmockit] which defines its mock expectations the same way. I think object initializers are really an elegant albeit hipster way to implement DSLs.

Although you can easily define the `Routes` class on your own, you might vote for this Camel [issue][jira] or [pull request][pr] if you want to have this in upstream Camel, too.

[camel-java-dsl]: https://camel.apache.org/java-dsl.html
[jira]: https://issues.apache.org/jira/browse/CAMEL-12608
[pr]: https://github.com/apache/camel/pull/2401
[object-initializers]: https://docs.oracle.com/javase/tutorial/java/javaOO/initial.html
[jmockit]: https://jmockit.github.io/tutorial/Mocking.html#expectation
