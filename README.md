# Aker Stamps

A microservice for managing the permissions of materials at Sanger. This is done through Stamps.

A Stamp is a way of applying restrictions on samples. Only the owner of a particular sample can apply a Stamp to it. For example, if a stamp lists user "dr6" amoung its "spend" permissions, then any material thus stamped will have "dr6 can order work on me" permission.

A material can have multiple stamps applied to it, and gain new permissions from each of them.

The service adheres to the [JSON API Specification](http://jsonapi.org/).

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