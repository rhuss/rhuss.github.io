---
title: "Blog winter is over"
date: 2026-04-04
slug: "blog-winter-is-over"
description: "After eight years of silence, this blog is back. A recap of what was, why it went quiet, and what's coming next."
tags: ["meta"]
license: "CC BY 4.0"
draft: true
---

The last post on this blog was about [Jib](https://github.com/GoogleContainerTools/jib), Google's daemonless Java image builder. That was July 2018. Almost eight years ago. Anybody remember when that was the latest hotness?

Before that, I wrote about Docker when Docker was still exciting, built a [Kubernetes cluster on Raspberry Pi 3](/kubernetes-on-raspberry-pi3/) nodes when that was still a weekend adventure, and spent way too many words on Jolokia and JMX. 27 posts between 2010 and 2018, then silence. If you've been reading tech blogs long enough, you know how that goes. So what breaks eight years of silence?
<!--more-->

## Why the silence

There's no dramatic story here.
No burnout, no life crisis.
I just stopped at some point because my writing energy went elsewhere.
I co-authored [Kubernetes Patterns](https://learning.oreilly.com/library/view/kubernetes-patterns-2nd/9781098131678/) with Bilgin Ibryam (first edition in 2019, second in 2023), and more recently finished [Generative AI on Kubernetes](https://learning.oreilly.com/library/view/generative-ai-on/9781098171919/) with Daniele Zonca in 2026.

<img src="/images/books-k8s-patterns-genai.png" alt="Kubernetes Patterns and Generative AI on Kubernetes" style="max-width: 350px; margin: 1em auto; display: block;" />

Writing books is a strange experience.
You pour months into a manuscript, and when it ships, you're proud and drained at the same time.
But once the last book was out in March 2026, something shifted. The pressure was gone, and I wanted to write shorter, more opinionated pieces again.

And then there's writing fatigue.
The gap between having something to say and actually sitting down to write it kept getting wider.
I suspect anyone who has ever maintained a blog knows this feeling.

## What changed

Here's the thing.
The tech landscape of 2026 looks nothing like 2018.
AI-first engineering isn't a conference buzzword anymore, it's how I work every day.
The way I write code, design systems, and think about developer experience has shifted more in the last two years than in the decade before.

Context engineering became something I care about deeply.
Not in the abstract "prompt engineering is the new hotness" sense, but in the practical "how do you structure specifications so that AI agents produce useful output" sense.
I've been working intensively with Spec Driven Development (especially [spec-kit](https://github.com/github/spec-kit) from GitHub), and I have opinions about it, even as the whole field is still taking shape.

When you find yourself explaining the same ideas in conversations, Slack threads, and pull request descriptions over and over again, that's usually a sign you should write them down properly.
So here we are.

## The AI in the room

Let's be honest: pretending AI isn't part of how I write would be absurd. I spend my days working with AI coding agents. Of course that bleeds into how I create content.

But this blog is also an experiment. I want to find a good workflow between human and machine for producing writing that's worth reading. Not AI-generated slop with a human name on it, and not a purist rejection of tools that genuinely help.

Here's how it works in practice. Every post goes through a pipeline I've built from [Claude Code](https://claude.ai/code) plugins: [cc-prose](https://github.com/rhuss/cc-prose) for voice consistency and AI pattern detection, [cc-copyedit](https://github.com/rhuss/cc-copyedit) for structural editing, and [cc-blog](https://github.com/rhuss/cc-blog) for managing the whole publishing workflow. These plugins act as guardrails, not ghostwriters.

The amount of AI involvement varies. A post like this one, where the value is personal perspective, is mostly me. AI helped with ideation, polishing, and wrangling the publishing machinery. A deep technical post, like the [JavaMail internals](/removing-attachments-with-javamail/) I wrote back in 2010, would lean harder on AI for research, code examples, and explanations. The thinking and the opinions stay mine.

Every post carries an [AI attribution tag](https://aiattribution.github.io) at the bottom. It follows a standardized format that tells you exactly what role AI played: how much of the content it generated, what kind of contributions it made, and whether I reviewed the output. No hiding, no guessing.

One thing I want to be clear about: regardless of how much AI is involved, I'm responsible for every word that goes out here. I review everything, I make the editorial calls, and if something is wrong or misleading, that's on me. This is the same principle behind the [Responsible Vibe Coding Guide](https://vibe-coding-manifesto.com/) that I co-created with colleagues to improve how AI is used in open source coding communities. The core idea applies to writing just as much as to code: use AI as a tool, but own the result.

This process won't be perfect from day one. I'm figuring it out as I go. If you notice something that reads off, or if you have thoughts on how human-AI content creation should work, the comment section below is exactly the right place for that. Feedback on the writing process is just as welcome as feedback on the content itself.

## What's coming

I have a rough idea of what I want to write about.

**Context engineering and Spec Driven Development.**
How I structure specifications for agentic coding workflows, what works, what fails, and why the "just give it a prompt" approach misses the point.
This will probably be a recurring theme.

**AI-first engineering, practically.**
Not the hype, not the doomer takes.
The actual day-to-day transformation: what changes when your coding partner has read more code than you ever will?
The challenges, the surprising wins, the things that still don't work.

**AgentOps on Kubernetes.**
Running agentic workloads on Kubernetes and OpenShift is a different beast than classic web services.
Agents are unpredictable, long-running, resource-hungry, and they talk to the outside world in ways that make security teams nervous.
I'm ramping up on this topic professionally, figuring out how to operate these workloads in a secure and scalable way.
Expect posts about the particular demands of AI agents and why your existing Deployment patterns won't cut it.

**Agentic coding projects.**
Personal tools and experiments that others might find useful.
I've been building quite a bit in this space and some of it deserves a proper write-up.

**The home K3s cluster.**
Five Raspberry Pi 4 nodes, running for over five years now. What started as the Raspberry Pi 3 experiment from 2016 has evolved into a proper home infrastructure. There are stories to tell about keeping a bare-metal cluster alive that long, and about how AI coding agents make managing it surprisingly flexible.

**Book-adjacent topics.**
Kubernetes patterns that didn't fit into the book, or that I've learned since.
Generative AI on Kubernetes in practice, beyond what made it into the manuscript.

**And everything else.**
Random observations, half-baked opinions, things that don't fit neatly into a category.
The kind of posts that make a personal blog a personal blog.

## Let's see

I'm not going to promise a posting schedule.
That kind of commitment didn't work last time, and I see no reason to repeat it.
I have more things to write about now than at any point during the old blog's run. Let's see if I can get them down to paper. If so, it should be a good ride.

<div class="ai-attribution">

[AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
