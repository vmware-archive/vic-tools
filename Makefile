# Copyright 2018 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL = /bin/bash

.PHONY: all check shellcheck dockerfile_lint
.DEFAULT_GOAL := all

all: check
check: shellcheck dockerfile_lint

shellcheck:
	@shellcheck **/*.sh

dockerfile_lint:
	@docker run -it --rm --privileged -v $(PWD):/root/ projectatomic/dockerfile-lint dockerfile_lint -p -f images/*/Dockerfile

