#!/bin/bash
# Copyright 2018 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
set -x

WORKSPACE_DIR=$(cd $(dirname "$0")/../../../.. && pwd)

# 6.0u3
ESX_60_VERSION="ob-5050593"
VC_60_VERSION="ob-5112509" # the cloudvm build corresponding to the vpx build

# 6.5u2
ESX_65_VERSION="ob-8935087"
VC_65_VERSION="ob-8307201"

# 6.7
ESX_67_VERSION="ob-8169922"
VC_67_VERSION="ob-8217866"


DEFAULT_TESTCASES=("tests/manual-test-cases")

DEFAULT_VIC_PRODUCT_BRANCH="master"
DEFAULT_VIC_PRODUCT_BUILD="*"

DEFAULT_PARALLEL_JOBS=4

echo "Target version: ${VSPHERE_VERSION}"
excludes=(--exclude skip)
case "$VSPHERE_VERSION" in
    "6.0")
        excludes+=(--exclude nsx)
        ESX_BUILD=${ESX_BUILD:-$ESX_60_VERSION}
        VC_BUILD=${VC_BUILD:-$VC_60_VERSION}
        ;;
    "6.5")
        ESX_BUILD=${ESX_BUILD:-$ESX_65_VERSION}
        VC_BUILD=${VC_BUILD:-$VC_65_VERSION}
        ;;
    "6.7")
        excludes+=(--exclude nsx --exclude hetero)
        ESX_BUILD=${ESX_BUILD:-$ESX_67_VERSION}
        VC_BUILD=${VC_BUILD:-$VC_67_VERSION}
        ;;
esac

testcases=("${@:-${DEFAULT_TESTCASES[@]}}")
${ARTIFACT_PREFIX:="vic-*"}
${GCS_BUCKET:="vic-product-ova-builds"}

VIC_PRODUCT_BRANCH=${VIC_PRODUCT_BRANCH:-${DEFAULT_VIC_PRODUCT_BRANCH}}
VIC_PRODUCT_BUILD=${VIC_PRODUCT_BUILD:-${DEFAULT_VIC_PRODUCT_BUILD}}
if [ "${VIC_PRODUCT_BRANCH}" == "${DEFAULT_VIC_PRODUCT_BRANCH}" ]; then
    GS_PATH="${GCS_BUCKET}"
else
    GS_PATH="${GCS_BUCKET}/${VIC_PRODUCT_BRANCH}"
fi
input=$(gsutil ls -l "gs://${GS_PATH}/${ARTIFACT_PREFIX}-${VIC_PRODUCT_BUILD}-*" | grep -v TOTAL | sort -k2 -r | head -n1 | xargs | cut -d ' ' -f 3 | xargs basename)
constructed_url="https://storage.googleapis.com/${GS_PATH}/${input}"
ARTIFACT_URL="${ARTIFACT_URL:-${constructed_url}}"
input=$(basename "${ARTIFACT_URL}")

pushd ${WORKSPACE_DIR}/vic-product
    echo "Downloading VIC Product OVA build $input... from ${ARTIFACT_URL}"
    n=0 && rm -f "${input}"
    until [[ $n -ge 5 ]]; do
        echo "Retry.. $n"
        echo "Downloading gcp file ${input} from ${ARTIFACT_URL}"
        wget --unlink -nv -O "${input}" "${ARTIFACT_URL}" && break;
        # clean up any residual file from failed download
        rm -f "${input}"
        ((n++))
        sleep 10;
    done

    if [[ ! -f $input ]]; then
        echo "VIC Product OVA download failed"
        exit 1
    fi
    echo "VIC Product OVA download complete..."

    PARALLEL_JOBS=${PARALLEL_JOBS:-${DEFAULT_PARALLEL_JOBS}}
    pabot --verbose --processes "${PARALLEL_JOBS}" -d report "${excludes[@]}" --variable ESX_VERSION:"${ESX_BUILD}" --variable VC_VERSION:"${VC_BUILD}" "${testcases[@]}"
    cat report/pabot_results/*/stdout.txt | grep -E '::|\.\.\.' | grep -E 'PASS|FAIL' > console.log

    # Pretty up the email results
    sed -i -e 's/^/<br>/g' console.log
    sed -i -e 's|PASS|<font color="green">PASS</font>|g' console.log
    sed -i -e 's|FAIL|<font color="red">FAIL</font>|g' console.log
    cp -R test-screenshots report 2>/dev/null || echo "no test-screenshots directory"
popd

