CLOUDIMAGES=packercloud.img testcloud.img

all: output-basic/ubuntu #output-hashistack/ubuntu

.PHONY: basic
basic: output-basic/ubuntu
output-basic/ubuntu: packercloud.img
	@echo Running packer build $@
	PACKER_LOG=1 packer build ubuntu.json

# .PHONY: hashistack
# hashistack: output-hashistack/ubuntu
# output-hashistack/ubuntu: packercloud.img
# 	@echo Running packer build $@
# 	PACKER_LOG=1 packer build ubuntu_hashistack.json

$(CLOUDIMAGES):
	@echo Creating $@
	cloud-localds $@ $(patsubst %.img,%.cfg,$@)

.PHONY: clean
clean:
	$(RM) -r output-*
	$(RM) $(CLOUDIMAGES)

.PHONY: distclean
distclean: clean
	$(RM) -r packer_cache

.PHONY: testbasic
testbasic:
	qemu-system-x86_64 -hda output-basic/ubuntu -m 2048 -enable-kvm -fda testcloud.img -serial mon:stdio

.PHONY: testhashistack
testhashistack: testcloud.img
	qemu-system-x86_64 -hda output-hashistack/ubuntu -m 2048 -enable-kvm -fda testcloud.img -nographic
