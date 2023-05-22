---
filename: /exuma-contracts/index
slug: index
type: toc
---

## Table of Contents

### Interfaces

{% assign interfaces = site.pages | where: "type", "interface" | sort: "title" %}
{% for page in interfaces %}
- [{{ page.title }}]({{ page.filename }})

{% endfor %}

### Contracts

{% assign contracts = site.pages | where: 'type', 'contract' | sort: "title"  %}
{% for page in contracts %}
- [{{ page.title }}]({{ page.filename }})

{% endfor %}

{{ page.slug }}
{{ page.anchor }}
