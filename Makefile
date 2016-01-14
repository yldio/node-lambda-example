role_name = lambda_basic_execution

upload: function-arn function.zip
	@aws lambda update-function-code \
		--function-name "$(shell cat function-arn)" \
		--publish \
		--zip-file fileb://function.zip

create-function: role-arn function.zip
	aws lambda create-function \
		--function-name "$(shell json name < package.json)" \
		--description "$(shell json description < package.json)" \
		--runtime nodejs \
		--role $(shell cat role-arn) \
		--handler index.handler \
		--zip-file fileb://function.zip \
		--output text --query FunctionArn \
		> $@

function-arn:
	@(aws lambda get-function \
		--function-name $(shell json name < package.json) \
		--output text --query Configuration.FunctionArn \
		> $@ || \
		(rm $@; ${MAKE} create-function function-arn))

role-arn:
	@(aws iam get-role \
		--role-name $(role_name) \
		--output text --query Role.Arn \
		> $@ || \
		(rm $@; ${MAKE} create-role role-arn))

create-role:
	@aws iam create-role \
		--role-name $(role_name) \
		--assume-role-policy-document file://role-policy-document.json
	@aws iam put-role-policy \
		--role-name $(role_name) \
		--policy-name Logging \
		--policy-document file://role-inline-policy.json

function.zip: index.js node_modules
	@zip -r $@ $^

node_modules: package.json
	@npm install

.PHONY: zip upload create-role create-function

