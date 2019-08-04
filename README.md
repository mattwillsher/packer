Packer config
=============

Set of Packer configs to create Ubuntu cloud images for use in QEMU.

*Basic image* Basic image with no additional software.

*Hashistack image* contains consul, nomad and vault.

Usage
-----

Needs:
* Packer installed (can be installed via scripts/hashistack.sh, with some modification)

Run `make` to build the images. See the [Makefile](Makefile) for more.

Future work ideas
-----------------

* Add variables to packer files to set
  * Cloud image version
  * Cloud image SHA
  * Tools version inside image

* Versioning, with data inside resulting image

* InSpec or similar tests
