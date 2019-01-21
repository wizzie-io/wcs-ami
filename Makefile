export AWS_MAX_ATTEMPTS = 360
export AWS_POLL_DELAY_SECONDS = 10

all: ami

output-dir:
	mkdir -p output

packer-validate:
	packer validate wcs-ami.json

ami: packer-validate output-dir
	packer build wcs-ami.json | tee output/packer.log
