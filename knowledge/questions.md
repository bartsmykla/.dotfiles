# Questions

## Where you could try to find a list of available iptables tables?

```sh
cat /proc/net/ip_tables_names
```

Source: [Discussion: iptables: how to list tables?](https://comp.os.linux.networking.narkive.com/fDfacHDC/iptables-how-to-list-tables#post4)

> When run this command on my VM (CentOS 8, iptables v1.8.4 (nf_tables))
> this file was empty, so maybe it's distribution related.

## What is `conntrack` (connection tracking)?

Links:

* [Blog Tigera: When Linux `conntrack` Is No Longer Your Friend](https://www.tigera.io/blog/when-linux-conntrack-is-no-longer-your-friend/)
* [Debian: `conntrack(8)` manual page](https://manpages.debian.org/testing/conntrack/conntrack.8.en.html)
* [Blog Cloudflare: `conntrack` Tales One Thousand And One Flows](https://blog.cloudflare.com/conntrack-tales-one-thousand-and-one-flows/)

## What is `SNAT`?

Links:

* [SNAT vs DNAT](https://ipwithease.com/snat-vs-dnat/)
