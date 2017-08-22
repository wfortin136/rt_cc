#!/bin/bash

VERSION=$1 

aws ecs register-task-definition --family piv-app --cli-input-json file://container-def.json --profile challenge-terraform
aws ecs update-service --cluster piv-app --service piv-app --task-definition piv-app:$VERSION --desired-count 1 --profile challenge-terraform
