---
layout: post
title: RasPi 3 Kubernetes Cluster - An Update
published: true
---

Our Ansible Playbooks for installing Kubernetes on a Raspberry Pi Cluster have been constantly updated and are now using the awesome [kubeadm][1]. The update to Kubernetes 1.6. was a bit tricky, though.

<!-- more -->

Recently I had the luck to meet Mr. [@kubernetesonarm][2] Lucas Käldström at the[ DevOps Gathering][3] where he demoed his multi-arch cluster. That was really impressing. Lucas really squeezes out the maximum what is possible these days with Raspberry Pis and other SOC devices on the Kubernetes platform.  Please follow his [Workshop][4] on GitHub for a multi-platform setup with ingress controller, persistent volumes, custom API servers and more. 

Needless to say that after returning home one of the first task was to update our [Ansible playbooks][5] for updating to Kubernetes 1.6 on my RasPi cluster. The goal of these playbooks are a bit different than Lucas workshop setup: Instead of living at the edge, the goal here is to provide an easy, automated and robust way to install a standard Kubernetes installation on a Raspberry Pi 3 cluster. `kubeadm` is a real great help and makes many things so much easier. However there are still some steps to do in addition.

After following the [workshop instructions][6] it turned out soon, that it was probably not the best time for the update. Kubernetes 1.6. has just been released and it turned out that last minute pre-release changes [broke kubeadm 1.6.0][7]. Luckily these were fixed quickly with 1.6.1. However the so called _self hosted_ mode of kubeadm broke, too (and is currently still [broken][8] in 1.6.1 but should be fixed soon). So the best bet for the moment is to use a standard install (with external processes for api-server et. al). 

Also this time I wanted to use [Weave][9] instead of Flannel as the overlay network. In turned out that this didn't worked on my cluster because every of my nodes got the same virtual Mac address assigned by Weave. That's because this address is [calculated][10] based on `/etc/machine-id`. And guess what. All my nodes had the _same machine id_ `9989a26f06984d6dbadc01770f018e3b`. This it what the base Hypriot 1.4.0 system decides to install (in fact it is derived by  `systemd-machine-id-setup` from `/var/lib/dbus/machine-id`). And every Hypriot installation out there has this very same machine-id ;-) For me it wasn't surprising, that this happened (well, developing bugs is our daily business ;-), but I was quite puzzled that this hasn't been a bigger [issue][11] yet, because I suspect that especially in cluster setups (may it be Docker Swarm or Kubernetes) at some point the nodes need their unique id. Of course most of the time the IP and hostname is enough. But for a more rigorous UUID `/etc/machine-id` is normally good fit.

After knowing this and re-creating the UUID on my own (with `dbus-uuidgen > /etc/machine-id`) everything works smoothly now again, so that I have a base Kubernetes 1.6 cluster with DNS and proper overlay network again. Uff, was quite a mouthful of work :) 

You find the installation instructions and the updated playbooks at [https://github.com/Project31/ansible-kubernetes-openshift-pi3][12]. If your router is configured properly, it takes not much more than half an hour to [setup the full cluster][13]. I did it several times now since last week, always starting afresh with flashing the SD cards. I can confirm that its reproducible and idempotent now ;-)

The next steps are to add persistent volumes with [Rook][14], [Træfik][15] as ingress controller and an own internal registry.

Feel free to give it a try and open many [issues][16] ;-)

[1]:	https://github.com/kubernetes/kubeadm
[2]:	https://twitter.com/kubernetesonarm
[3]:	https://devops-gathering.io/
[4]:	https://github.com/luxas/kubeadm-workshop
[5]:	https://github.com/Project31/ansible-kubernetes-openshift-pi3
[6]:	https://github.com/luxas/kubeadm-workshop/blob/master/README.md
[7]:	https://github.com/kubernetes/kubeadm/issues/212
[8]:	https://github.com/luxas/kubeadm-workshop/issues/8
[9]:	https://github.com/weaveworks/weave
[10]:	https://github.com/weaveworks/weave/blob/916ff7aa3979fced84fceef1635ab8c868d71e25/net/uuid.go#L26
[11]:	https://github.com/hypriot/image-builder-rpi/issues/167
[12]:	https://github.com/Project31/ansible-kubernetes-openshift-pi3
[13]:	https://github.com/Project31/ansible-kubernetes-openshift-pi3#ansible-playbooks
[14]:	https://github.com/rook/rook
[15]:	https://traefik.io/
[16]:	https://github.com/Project31/ansible-kubernetes-openshift-pi3/issues/new