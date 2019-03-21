__PHONY__: build build-testing

core-binary:
	docker pull kinecosystem/stellar-core:latest
	docker run -d --name stellar-core-binary --rm --entrypoint sleep kinecosystem/stellar-core:latest 5
	docker cp $$(docker inspect --format="{{.Id}}" stellar-core-binary):/usr/local/bin/stellar-core ./

horizon-binary:
	docker pull kinecosystem/horizon:latest
	docker run -d --name horizon-binary --rm --entrypoint sleep kinecosystem/horizon:latest 5
	docker cp $$(docker inspect --format="{{.Id}}" horizon-binary):/usr/local/bin/horizon ./

build: core-binary horizon-binary
	docker build -t kinecosystem/blockchain-quickstart -f Dockerfile .

build-testing: core-binary horizon-binary
	docker build -t kinecosystem/blockchain-quickstart:testing -f Dockerfile.testing .
