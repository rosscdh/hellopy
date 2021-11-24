.PHONY: all build login push run

NAME     				:= rosscdh/hellopy-demo
TAG      				:= $$(git log -1 --pretty=%h)
CURRENT_RELEASE_TAG 	?= $$(bash ci/scripts/current_version.sh)
NEXT_RELEASE_TAG 		:= $$(pushd ${PWD}/src > /dev/null;semantic-release print-version;popd > /dev/null)
VERSION  				:= ${NAME}:${TAG}
LATEST   				:= ${NAME}:latest

ENVIRONMENT?=demo

BUILD_REPO_ORIGIN=$$(git config --get remote.origin.url)
BUILD_COMMIT_SHA1:=$$(git rev-parse --short HEAD)
BUILD_COMMIT_DATE:=$$(git log -1 --date=short --pretty=format:%ct)
BUILD_BRANCH:=$$(git symbolic-ref --short HEAD)
BUILD_DATE:=$$(date -u +"%Y-%m-%dT%H:%M:%SZ")


all: build login push

#
# 1. do your work; and when ready 
# git commit -am":lipstick: my message" where the emoji is one of the major,minor,patch keys
# bump the release version, this will automatically tag your work accorting to src/setup.py
#
bump_release_version:
	@echo ---------------------------------
	@echo Bump the release version from: ${CURRENT_RELEASE_TAG} to: ${NEXT_RELEASE_TAG}
	@echo ---------------------------------
	bash ci/scripts/bump_release_version.sh ${PWD}/src


build:
	docker build -t ${LATEST} -t ${VERSION} \
		--build-arg BUILD_COMMIT_SHA1=${BUILD_COMMIT_SHA1} \
		--build-arg BUILD_COMMIT_DATE=${BUILD_COMMIT_DATE} \
		--build-arg BUILD_BRANCH=${BUILD_BRANCH} \
		--build-arg BUILD_DATE=${BUILD_DATE} \
		--build-arg BUILD_REPO_ORIGIN=${BUILD_REPO_ORIGIN} \
		.
	bash ci/scripts/set-app-tag.sh ${LATEST} ${NAME} ${CURRENT_RELEASE_TAG}

local-test:
	docker run --rm -it -v ${PWD}/src:/src --env-file .env --entrypoint /venv/bin/python ${LATEST} manage.py test

test:
	docker run --rm --env-file .env.example --entrypoint /venv/bin/python ${LATEST} manage.py test

ci-test:
	docker run --rm --env-file .env.test --network="host" --entrypoint /venv/bin/python ${LATEST} manage.py test

login:
 	$(aws ecr get-login-password --profile MOS-INFRA --region eu-west-2 | docker login --username AWS --password-stdin 439304389429.dkr.ecr.eu-west-2.amazonaws.com)

push:
	@echo ---------------------------------
	@echo Will Push: ${NAME}:${CURRENT_RELEASE_TAG}
	@echo ---------------------------------

	@docker push ${VERSION}
	@docker push ${NAME}:${CURRENT_RELEASE_TAG}
	@echo ---------------------------------
	@echo Pushed: ${NAME}:${CURRENT_RELEASE_TAG}
	@echo ---------------------------------

render-k8s:
	@echo ---------------------------------
	@echo Will render k8s for: ${NAME}:${CURRENT_RELEASE_TAG} to ${PWD}/k8s/argocd/rendered/${ENVIRONMENT}/app.yaml
	@echo ---------------------------------
	mkdir -p ${PWD}/k8s/argocd/rendered/${ENVIRONMENT} | true
	bash ci/scripts/render-k8s.sh hellopy-demo ${NAME}:${CURRENT_RELEASE_TAG} ${PWD}/k8s/argocd/overlays/${ENVIRONMENT} ${PWD}/k8s/argocd/rendered/${ENVIRONMENT}/app.yaml
