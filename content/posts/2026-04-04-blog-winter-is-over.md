---
title: "Blog winter is over"
date: 2026-04-04
slug: "blog-winter-is-over"
description: "After eight years of silence, this blog is back. A recap of what was, why it went quiet, and what's coming next, from context engineering to AgentOps on Kubernetes."
tags: ["meta", "writing", "ai", "kubernetes"]
keywords: ["blog restart", "context engineering", "AgentOps", "Kubernetes", "AI engineering", "Spec Driven Development"]
images: ["/images/blog-winter-is-over/og.png"]
license: "CC BY 4.0"
draft: false
---

The last post on this blog was about [Jib](https://github.com/GoogleContainerTools/jib), Google's daemonless Java image builder. That was July 2018. Almost eight years ago. Anybody remember when that was the latest hotness?

Before that, I wrote about Docker when Docker was still exciting and built a [Kubernetes cluster on Raspberry Pi 3](/kubernetes-on-raspberry-pi3/) nodes when that was still a weekend adventure. I spent way many words on Jolokia and JMX. 27 posts between 2010 and 2018, then silence. If you've been reading tech blogs long enough, you know how that goes.

So what breaks eight years of silence?
<!--more-->

## Why the silence

There's no dramatic story here, no burnout or life crisis.
I just stopped at some point because my writing energy went elsewhere.
I co-authored [Kubernetes Patterns](https://learning.oreilly.com/library/view/kubernetes-patterns-2nd/9781098131678/) with Bilgin Ibryam (first edition in 2019, second in 2023). More recently, I finished [Generative AI on Kubernetes](https://learning.oreilly.com/library/view/generative-ai-on/9781098171919/) with Daniele Zonca in 2026.

<img src="/images/blog-winter-is-over/books-k8s-patterns-genai.png" alt="Kubernetes Patterns and Generative AI on Kubernetes" style="max-width: 350px; margin: 1em auto; display: block;" />

Writing books is a strange experience.
You pour months into a manuscript, and when it ships, you're proud and drained at the same time.
But once the last book was out in March 2026, something shifted. The pressure was gone, the gap between having something to say and sitting down to write it started closing, and I wanted to write shorter, more opinionated pieces again.

## What changed

The tech world of 2026 looks nothing like 2018. AI-first engineering isn't a conference buzzword anymore. It's how I work every day. The way I write code, design systems, and think about developer experience has shifted more in the last year than in the decade before. Last month I scaffolded a complete operator in two days that would have taken two weeks in 2018, and most of my work was writing the specification, not the code.

Context engineering became something I care about deeply. Not in the abstract "prompt engineering" sense, but in the practical "how do you structure specifications so that AI agents produce useful output" sense. I've been deep into Spec Driven Development, particularly [spec-kit](https://github.com/github/spec-kit) from GitHub. I have opinions about it, even as the whole field is still taking shape.

When you find yourself explaining the same ideas in conversations, Slack threads, and pull request descriptions over and over again, that's usually a sign you should write them down properly.

## What's coming

The topic I keep coming back to is **context engineering and Spec Driven Development**: how I structure specifications for agentic coding workflows, what works, what fails, and why the "just give it a prompt" approach misses the point. This will probably be a recurring theme, because the field is moving fast and there's a lot to figure out in public.

Close behind is **AgentOps on Kubernetes**. Running agentic workloads on Kubernetes and OpenShift is a different beast than classic web services. Agents are unpredictable, long-running, and resource-hungry. They talk to the outside world in ways that make security teams nervous. I'm ramping up on this topic professionally, figuring out how to operate these workloads in a secure and scalable way. Expect posts about the particular demands of AI agents and why your existing Deployment patterns won't cut it.

Beyond those two, expect posts about AI-first engineering in daily practice (the surprising wins, the things that still don't work), agentic coding projects and tools, the home K3s cluster that's been running on five Raspberry Pi 4 nodes for over five years, book-adjacent Kubernetes patterns, and whatever else catches my attention.

## On AI and this blog

Since AI changed how I work, it naturally changed how I write too. I use AI tools for ideation, polishing, and managing the publishing workflow. The thinking and the opinions stay mine. Every post carries an [AI attribution tag](https://aiattribution.github.io) at the bottom so you know exactly what role AI played. I apply the same principle I advocate in the [Responsible Vibe Coding Guide](https://vibe-coding-manifesto.com/): use AI as a tool, but own the result. I'll write more about the process in a future post.

## Let's see

I'm not going to promise a posting schedule. That kind of commitment didn't work last time, and I see no reason to repeat it. But I have more things to write about now than at any point during the old blog's run. Eight years ago, Jib was the latest hotness. The next post won't take that long.

<div class="ai-attribution">

[AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
