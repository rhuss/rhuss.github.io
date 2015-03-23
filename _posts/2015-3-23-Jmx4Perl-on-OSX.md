---
layout: post
title: Jmx4Perl on OS X
published: true
---

The HTTP-JMX Bridge [Jolokia][1] allows easy access to JMX. It exposes all JMX information and operations via an REST-like interface and has tons of nifty features. [Jmx4Perl][2] on the other side is a client for Jolokia, which beside Perl access modules also provides quite some nice CLI tools for accessing and installing Jolokia. This post explains how install these tools on OS X.
<!-- more -->

Jmx4Perl provides some nice CLI commands:

* [jmx4perl][3] is a simple access tool which is useful for quick queries and ideal for inclusion in shell scripts.
* [j4psh][4] is a powerful interactive, readline based JMX shell with tab completion and syntax highlighting.
* [jolokia][5] is a tool for managing Jolokia agents (downloading, changing init properties etc.)

All this tools are very helpful in order to explore the JMX namespace and installing the agent. They all are fairly good documented and each of them probably deserves an own blog post.

However, the installation or Perl modules and programs is a bit tedious.  Although [cpan][6] helps here and also resolves transitive dependencies it's still a lengthy process, which fails from time to time. Native Linux packages are planned, but don't hold your breath ;-).

For OS X users with [Homebrew][7] can install Jmx4Perl quite easily, though:

````bash
$ brew install cpanm
$ cpanm --sudo install JMX::Jmx4Perl
````

This will do all the heavy lifting for you and at the end all the fine Jmx4Perl tools are installed and available under `/usr/local/bin`. 

`j4psh` uses `libreadline` for the input handling. For the best user experience GNU ReadLine is recommended. Unfortunately, OS X doesn't ship with a *true* `libreadline` but with `libedit` which is a stripped down version of libreadline. In order to use GNU readline, some tricks are needed which are described in this [recipe][8]. For me, the following steps worked (but are probably a bit "dirty"):

````bash
$ brew install readline
$ brew link --force readline
$ sudo mv /usr/lib/libreadline.dylib /tmp/libreadline.dylib 
$ cpanm --sudo Term::ReadLine::Gnu
$ sudo mv /tmp/libreadline.dylib /usr/lib/libreadline.dylib
$ brew unlink readline
````

These steps are really only necessary if you need advanced readline functionality (or a coloured prompt in j4psh ;-).




[1]:	http://www.jolokia.org
[2]:	http://search.cpan.org/~roland/jmx4perl/
[3]:	http://search.cpan.org/~roland/jmx4perl/scripts/jmx4perl
[4]:	http://search.cpan.org/~roland/jmx4perl/scripts/j4psh
[5]:	http://search.cpan.org/~roland/jmx4perl/scripts/jolokia
[6]:	http://search.cpan.org/~andk/CPAN/scripts/cpan
[7]:	http://brew.sh/
[8]:	http://blogs.perl.org/users/aristotle/2013/07/easy-osx-termreadlinegnu.html