SHELL := $(SHELL) -e
VARS_FILE  := google.tfvars
PLAN_FILE  := google.tfplan
STATE_FILE := google.tfstate
OUT_FILE   := properties.yml

all: manifest deploy

manifest:
	terraform get -update
	terraform plan -var-file ${VARS_FILE} -out ${PLAN_FILE}

deploy:
	terraform apply -var-file ${VARS_FILE}
	terraform output | ./yamler meta tf > ${OUT_FILE}

destroy:
	terraform plan -destroy -var-file ${VARS_FILE} -out ${PLAN_FILE}
	terraform apply ${PLAN_FILE}

clean:
	rm -f ${PLAN_FILE}
	rm -f ${STATE_FILE}

cloud:
	spruce merge --prune meta properties.yml cloud.yml | spruce json | cc-me

.PHONY: all manifest deploy destroy clean cloud
