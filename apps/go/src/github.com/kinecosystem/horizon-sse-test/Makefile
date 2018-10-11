.PHONY: vendor clean
.DEFAULT_GOAL: default

glide_version := v0.13.1
glide_arch := linux-amd64
glide_url := https://github.com/Masterminds/glide/releases/download/$(glide_version)/glide-$(glide_version)-$(glide_arch).tar.gz

default: glide vendor

glide:
	curl -sSLo glide.tar.gz $(glide_url)
	tar -xf ./glide.tar.gz
	mv ./$(glide_arch)/glide ./glide
	rm -rf ./$(glide_arch) ./glide.tar.gz

vendor:
	./glide install

clean:
	rm -rf vendor glide
