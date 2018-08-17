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

SHELL_FILES = $(shell find . -type f -name '*.sh')

.PHONY: all check shellcheck
.DEFAULT_GOAL := all

all: check
check: shellcheck

shellcheck:
	@docker run --rm -v $(PWD):/root -w /root -t caarlos0/shellcheck shellcheck $(SHELL_FILES)
