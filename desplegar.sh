#!/bin/bash

aws cloudformation deploy \
--template-file prueba.yml \
--stack-name "miPrueba" \
--capabilities CAPABILITY_NAMED_IAM
