# Aker Stamps

A microservice for managing the permissions of materials at Sanger. This is done through Stamps.

A Stamp is a way of applying restrictions on samples. Only the owner of a particular sample can apply a Stamp to it. For example, if a stamp lists user "dr6" amoung its "spend" permissions, then any material thus stamped will have "dr6 can order work on me" permission.

A material can have multiple stamps applied to it, and gain new permissions from each of them.

The service adheres to the [JSON API Specification](http://jsonapi.org/), with certain qualifications:

1. Permissions and Materials are immutable once created. They can be destroyed, but not modified.
2. Relationships cannot be altered via relationship urls, because permissions and materials cannot be modified. (Puts and patches to relationship urls will be rejected.)
3. Only the owner of a stamp can modify it (e.g. rename it, create or remove permissions related to it, or delete it). The owner of a stamp is whoever created it.
4. Users are identified by a JWT.
5. Only the owner of a particular material (identified from the materials service) can stamp or unstamp it.
6. The permissions for a stamp can be set by posting to /api/v1/stamps/{stamp_id}/set_permissions. Any preexisting permissions will be replaced if the request is successful.
7. A batch of materials can be stamped (or unstamped) in one operation by posting an array of material uuids to /api/v1/stamps/{stamp_id}/apply or /api/v1/stamps/{stamp_id}/unapply. In either case, the user must own all listed materials.

Dependencies
------------

Aker Stamps is dependent on the [Aker Materials service](https://github.com/sanger/aker-materials).

Ruby version
------------

`ruby-2.4.1`

Resources
---------

```
--------------     ---------     -----------------
| Permission | >-- | Stamp | --< | StampMaterial |
--------------     ---------     -----------------
```

How to run the test suite
-------------------------

The test suite can be run through [rspec](http://rspec.info/):

`bundle exec rspec`