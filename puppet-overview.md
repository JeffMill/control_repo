# Puppet Notes

Puppet home page is [here](https://puppet.com)

Good tutorial is [here](https://www.tutorialspoint.com/puppet)

## configuration management overview

install server, configure server - requires a number of scripts

developer sends software updates to ops

ops deploys updates to servers

manager can decide that more servers are needed at any time

### w/o automation tool

* config lots of servers
* scale new servers
* environment dependency
* lack of scalability
* infrastructure not portable
* lack of flexibility
* no insight into infrastructure (properties of agents, etc.)

### config mgmt (CM) is systematic

system state + auditing

* what components need to change?
* redo an implementation
* revert to previous version
* replace an incorrect component

consistency in infrastructure

* system design, state, environment
* known and trusted
* record changes

## infrastructure as code (IaC)

* provision as code, rather than handling each phase.
* data driven: "user", "shell", "ensure"

## What is puppet

* orchestration
* provisioning
* deploy
* configuration - distinct configuration for every host
* Idempotency - safe to run same configuration multiple times on a machine
* Cross-platform - has Resource Abstraction Layer (RAL) to abstract differences

continuously checks that desired config is in place.
if altered, will revert to required config.

does dynamic scale up, scale down.

### Master-agent architecture

master: handles configuration work. Relies on agents to apply configuration to nodes.

Config Repository: Where all nodes and master-related configuration is stored. Used by master.

Facts: details related to node used for analyzing current status.

agent: Managed by master. Perform work on nodes.

Catalog: master compiles catalog for desired state of agent. These catalogs are applied to target machines.

agent report back to master confirming all configurations are applied.

### Communication (over SSL)

1. agent requests master certificate
2. master sends master certificate
3. master requests agent certificate
4. agent sends agent certificate
5. agent requests configuration data
6. master sends configuration data

**TODO:** Verify above.

* master collects details of target machine, using factor on all agents (similar to Ohai in Chef)
* agent returns machine level configuration details.
* master compares retrieved config with defined config.
* Creates catalog and sends to targeted agents.
* agent applies configurations to get to desired state.
* Once in desired state, agent sends report back.

## Puppet Components

Manifest:

* instructions for an agent
* Contains Ruby code (.pp extension)

Modules:

* compilation of manifests, facts, templates, files

Templates:

* Use Ruby expressions to develop custom content.
* Defined in manifests.
* e.g. `Listen <% = @httpd_port %>`
  * `httpd_port` is defined in manifest that references this template

Static Files:

* General files that are simply copied to location.

Resource:

* Describes an aspect of a system, e.g. a specific service or package

Providers:

* Fulfill a particular resource

Factor:

* Describes facts about a agent, e.g. network settings
* Facts can be used in manifests as variables.

MCollective:

* Allows jobs to be executed in parallel on agents

Catalogs:

* Compilation of all resources for a given agent.
* Describes desired state of each resource on a agent
* Describes relationship between resources

Reports:

* Sent back from a agent to indicate current state
