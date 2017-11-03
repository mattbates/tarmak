.. proposals:

Proposals
=========

This section should contain design and implementation proposals for Tarmak.
Once the proposal has been implemented it should be moved to the regular user
and/or developer documentation.


Implement a Tarmak Terraform provider
-------------------------------------

Motivations
***********

Right now the Terraform code for the AWS provider consists of multiple
separate stacks_ (state, network, tools, vault, kubernetes).The main reason for the 
different stacks was to enable operations between the various stages of the resource
spin-up. These include (but not limited to):

- Bastion node needs to be up for other instances to check into Wing.
- Vault needs to be up and initialised, before PKI resources are created.
- Vault needs to contain a cluster's PKI resources, before Kubernetes instances
  can be created (``init-tokens``).

Design ideas
************

The proposal is to implement a Tarmak provider_ for Terraform, with at least these 
three resources.

.. _provider: https://www.terraform.io/docs/plugins/provider.html

``tarmak_bastion_instance``
~~~~~~~~~~~~~~~~~~~~~~~~~~~

A bastion instance.

::

  Input:
  - Bastion IP address or hostname
  - Username for SSH

  Blocks until the Wing API server is running.

``tarmak_vault_cluster``
~~~~~~~~~~~~~~~~~~~~~~~~

A Vault cluster.

::

  Input:
  - List of Vault internal FQDN or IP addresses

  Blocks until vault is ready.


``tarmak_vault_instance_role``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This creates (once per role) an init token for such instances in Vault. 

::

  Input:
  - Name of Vault cluster
  - Role name

  Output:
  - init_token per role


  Blocks until init token is setup.


Difficulties
************

The main difficulty is communication with the Tarmak process, as
Terraform is run within a Docker container with no communication available to
the main Tarmak process (stdin/out is used by the Terraform main process).

The proposal suggests that all ``terraform-provider-tarmak`` resources block
until the point when the main Tarmak process connects using another exec to a
so-called ``tarmak-connector`` executable that speaks via a local Unix socket
to the ``terraform-provider-tarmak``.

This provides a secure and platform-independent channel between Tarmak and
``terraform-provider-tarmak``.

::

   <<Tarmak>>  -- launches -- <<terraform|container>> 

       stdIN/OUT -- exec into  ---- <<exec terraform apply>>
                                    <<subprocess terraform-provider-tarmak
                                        |
                                    unix socket
                                        |
       stdIN/OUT -- exec into  ---- <<exec tarmak-connector>>


The protocol on that channel chould either be a Unix socket communication
using Kubernetes API features or `net/rpc <https://golang.org/pkg/net/rpc/>`_.

Initial proof-of-concept
************************

An initial proof-of-concept has been explored to test how the Terraform plugin model 
looks like. Although it's not really having anything implemented at this point, 
it might serve as a starting point.
