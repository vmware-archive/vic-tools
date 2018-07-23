#!/bin/bash
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
set -eu -o pipefail && [ -n "${DEBUG:-}" ] && set -x

DEFAULT_API_ENDPOINT="https://api.github.com/repos/"
DEFAULT_HEADERS=("Accept: application/vnd.github.symmetra-preview+json")
DEFAULT_CURL_ARGS=("-s")
DEFAULT_REPO="vmware/vic-tasks"
DEFAULT_MAX_LABELS=1000

API_ENDPOINT=${API_ENDPOINT:-${DEFAULT_API_ENDPOINT}}
HEADERS=("${HEADERS[@]:-${DEFAULT_HEADERS[@]}}")
CURL_ARGS=("${CURL_ARGS[@]:-${DEFAULT_CURL_ARGS[@]}}")
REPO=${REPO:-${DEFAULT_REPO}}
MAX_LABELS=${MAX_LABELS:-${DEFAULT_MAX_LABELS}}

HEADERS=("${HEADERS[@]}" "Authorization: token ${GITHUB_TOKEN?"GitHub API token must be supplied"}")
HEADER_ARGS=("${HEADERS[@]/#/"-H"}")

# Colors from https://material.io/design/color/#tools-for-picking-colors
declare -A colors
colors=(
  [red]="FFCDD2"
  [pink]="F8BBD0"
  [purple]="E1BEE7"
  ["deep purple"]="D1C4E9"
  [indigo]="C5CAE9"
  [blue]="BBDEFB"
  ["light blue"]="B3E5FC"
  [cyan]="B2EBF2"
  [teal]="B2DFDB"
  [green]="C8E6C9"
  ["light green"]="DCEDC8"
  [lime]="F0F4C3"
  [yellow]="FFF9C4"
  [amber]="FFECB3"
  [orange]="FFE0B2"
  ["deep orange"]="FFCCBC"
  [brown]="D7CCC8"
  [gray]="F5F5F5"
  ["blue gray"]="CFD8DC"
)

declare -A assigned_colors
assigned_colors=(
  [status]="${colors[red]}"
  [commitment]="${colors[purple]}"
  [area]="${colors[teal]}"
  [component]="${colors[cyan]}"
  [source]="${colors[green]}"
  [kind]="${colors[indigo]}"
  [product]="${colors[amber]}"
  [impact]="${colors[brown]}"
  [resolution]="${colors["blue gray"]}"
)


# Determines whether a label already exists
#
# Arguments:
# 1: the label name
#
# Returns:
# N/A
#
# Exits:
# 0: the label exists
# 1: the label does not exist
label-exists () {
    : "${1?"Usage: ${FUNCNAME[0]} LABEL"}"

    args=("-w%{http_code}\n" "${HEADER_ARGS[@]}" "${CURL_ARGS[@]}")
    code=$(curl "${args[@]}" "${API_ENDPOINT%/}/${REPO}/labels/${1// /%20}" | tail -n1)

    [ "$code" -eq 200 ]
}

# Updates the description and color associated with an existing label
#
# Arguments:
# 1: the label name
# 2: the label description
# 3: the label color
#
# Returns:
# N/A
#
# Exits:
# 0: the operation succeeded
# 1: the operation failed
label-update () {
    : "${2?"Usage: ${FUNCNAME[0]} LABEL DESCRIPTION [COLOR]"}"

    if [ -z "$3" ]
    then
        data="{\"description\": \"$2\"}"
    else
        data="{\"description\": \"$2\", \"color\": \"$3\"}"
    fi
    args=("--data" "${data}" "-XPATCH" "-w%{http_code}\n" "${HEADER_ARGS[@]}" "${CURL_ARGS[@]}")
    code=$(curl "${args[@]}" "${API_ENDPOINT%/}/${REPO}/labels/${1// /%20}" | tail -n1)

    [ "$code" -eq 200 ]
}

# Creates a label with the given description and color
#
# Arguments:
# 1: the label name
# 2: the label description
# 3: the label color
#
# Returns:
# N/A
#
# Exits:
# 0: the operation succeeded
# 1: the operation failed
label-create () {
    : "${2?"Usage: ${FUNCNAME[0]} LABEL DESCRIPTION [COLOR]"}"

    if [ -z "$3" ]
    then
        data="{\"name\":\"$1\", \"description\": \"$2\"}"
    else
        data="{\"name\":\"$1\", \"description\": \"$2\", \"color\": \"$3\"}"
    fi
    args=("--data" "${data}" "-w%{http_code}\n" "${HEADER_ARGS[@]}" "${CURL_ARGS[@]}")
    code=$(curl "${args[@]}" "${API_ENDPOINT%/}/${REPO}/labels" | tail -n1)

    [ "$code" -eq 201 ]
}

# Creates a label with the given description and color, or updates one that exists
#
# Arguments:
# 1: the label name
# 2: the label description
# 3: the label color
#
# Returns:
# N/A
#
# Exits:
# 0: the operation succeeded
# 1: the operation failed
label-merge () {
    : "${2?"Usage: ${FUNCNAME[0]} LABEL DESCRIPTION [COLOR]"}"

    if label-exists "$1"
    then
        label-update "$1" "$2" "$3"
    else
        label-create "$1" "$2" "$3"
    fi
}

# Creates a set of labels with a common prefix, updating the description and color of existing labels as necessary
#
# Arguments:
# 1: the label prefix
# 2: (pass-by-name) an associative array of label to description, with hyphens instead of slashes
# 3: the color for labels with the supplied prefix
#
# Returns:
# Warning strings about any unexpected labels which already exist with a given prefix
merge () {
    : "${3?"Usage: ${FUNCNAME[0]} PREFIX {LABEL:DESCRIPTION} COLOR"}"

    prefix="$1"
    l="$( declare -p "$2" )"
    eval "declare -A labels=${l#*=}"
    color="$3"

    expected=()
    # The array is declared in the eval above
    # shellcheck disable=SC2154
    for label in "${!labels[@]}"; do
        name="${prefix}/${label//_/\/}"
        description="${labels[$label]}"

        label-merge "${name}" "${description}" "${color}"

        expected+=(${name})
    done

    args=("${HEADER_ARGS[@]}" "${CURL_ARGS[@]}")
    existing=("$(curl "${args[@]}" "${API_ENDPOINT%/}/${REPO}/labels?per_page=${MAX_LABELS}" | \
               jq ".[] | .name | select(select(startswith(\"${prefix}/\")) | in({$(printf '"%s":0,' "${expected[@]}")}) != true)")")
    printf "WARNING: unexpected ${prefix} label %s\n" "${existing[@]}"
}

merge-oneoff () {
    label-merge "Epic" "Represents a ZenHub Epic" "9FA8DA"

    if [ "vmware/vic-tasks" != "${REPO}" ] && [ "vmware/vic-planning" != "${REPO}" ]
    then
        label-merge "help wanted" "A well-defined issue on which a pull request would be especially welcome" "${colors[orange]}"

        label-merge "cla-not-required" "" "ffffff"
        label-merge "cla-rejected" "" "fc2929"
    fi
}

merge-severity () {
    label-merge "severity/0-maximal" "Among the most severe issues imaginable. Use sparingly." "D32F2F" # (E.g., guaranteed data loss)
    label-merge "severity/1-critical" "Relates to a key use-case of the product. Often impacts many users." "E64A19" # (E.g., component crashes; missing feature blocking mass adoption)
    label-merge "severity/2-serious" "High usability or functional impact. Often has no workaround." "F57C00" # (E.g., advertised functionality does not work; core part of a new feature; refactoring code that is a recurring pain point)
    label-merge "severity/3-moderate" "Medium usability or functional impact. Potentially has an inconvenient workaround." "FFA000" # (E.g., API fails intermittently, but can be retried; optional part of a new feature; refactoring to improve maintainability)
    label-merge "severity/4-minor" "Low usability or functional impact. Often has an easy workaround." "FBC02D" # (E.g., short form of CLI argument causes failure, but long form works fine; nice-to-have part of a new feature; refactoring to improve readability)
    label-merge "severity/5-minimal" "Does not affect the ability the use the product in any way." "689F38" # (E.g., a typo which does not affect clarity; purely asthetic refactoring)
}

merge-products () {
    declare -A products
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    products=(
            [admiral]="Related to the vSphere Integrated Containers Managment Portal"
            [engine]="Related to the vSphere Integrated Containers Engine"
            [govmomi]="Related to the Go library for interacting with VMware vSphere APIs"
            [harbor]="Related to the VMware vSphere Integrated Containers Registry"
            [ova]="Related to the OVA packaging of vSphere Integrated Containers"
    )

    if [ "vmware/vic" == "${REPO}" ] || [ "vmware/vic-ui" == "${REPO}" ]
    then
        unset "products[engine]"
    fi

    merge "product" products "${assigned_colors[product]}"
}

merge-areas () {
    declare -A areas
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    areas=()
    if [ "vmware/vic" == "${REPO}" ]
    then
        areas+=(
            [api]="The Vritual Container Host management API"
            [cli]="The Vritual Container Host management CLI (vic-machine)"
            [diagnostics]="Utilities, procedures, and output to help to identify errors"
            [docker]="Support for the Docker operations"
            [kubernetes]="Support for the Kubernetes operations"
            [lifecycle]="Creation, management, and deletion of Virtual Container Hosts"
            [networking]="Networking-related functionality"
            [security]="Management of security functionality and other issues that impact security"
            [storage]="Storage-related functionality"
            [ui]="The Virtual Container Host administration UI"
            [ux]="Issues related to user experience"
            [vsphere]="Intergration and interoperation with vSphere"
        )
    elif [ "vmware/vic-product" == "${REPO}" ]
    then
        areas+=(
            [diagnostics]="Utilities, procedures, and output to help to identify errors"
            [lifecycle]="Installation, initialization, upgrade, and uninstallation"
            [pub]="Published documentation for users of all roles"
            [pub_appdev]="Published documentation for application developers"
            [pub_cloudadmin]="Published documentation for cloud administrators"
            [pub_vsphere]="Published documentation for vSphere administrators"
            [security]="Management of security functionality and other issues that impact security"
            [ui]="The Getting Started page"
        )
    elif [ "vmware/vic-tasks" == "${REPO}" ]
    then
        areas+=(
            [customers]="Work related to customer interaction"
            [operations]="Work related to operating our infrastructure"
            [process]="Work related to our development process"
            [staffing]="Work related to our organization"
        )
    elif [ "vmware/vic-tools" == "${REPO}" ]
    then
        areas+=(
            [automation]="Reducing required human interaction"
            [monitoring]="Tracking and reporting metrics and status"
            [utilities]="Abstracting common functionality"
        )
    elif [ "vmware/vic-ui" == "${REPO}" ]
    then
        areas+=(
            [compute]="Screens related to display and selection of compute-related settings"
            [datagrid]="Display of the VCH datagrid and associated actions and menus"
            [general]="Screens related to display and selection of general settings"
            [lifecycle]="Installation, initialization, upgrade, and uninstallation"
            [networking]="Screens related to display and selection of networking-related settings"
            [registry]="Screens related to display and selection of registry-related settings"
            [security]="Screens related to display and selection of security-related settings"
            [storage]="Screens related to display and selection of storage-related settings"
            [summary]="Display of requested settings for confirmation"
        )
    fi

    merge "area" areas "${assigned_colors[area]}"
}

merge-components () {
    declare -A components
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    components=(
            [infrastructure]="Infrastructure related to building and testing"
            [test]="Tests not covered by a more specific component label"
            [test_integration]="Integration tests (run continuously by Drone)"
            [test_scenario]="Scenario tests (run periodically via Jenkins)"
    )

    if [ "vmware/vic" == "${REPO}" ]
    then
        components+=(
            [config]=""
            [install]=""
            [isos]=""
            [gateway_vmomi]=""
            [persona]=""
            [persona_docker]=""
            [persona_kublet]=""
            [portlayer]=""
            [portlayer_execution]=""
            [portlayer_interaction]=""
            [portlayer_network]=""
            [portlayer_storage]=""
            [registry]=""
            [test_longevity]=""
            [tether]=""
            [trace]=""
            [utilities]=""
            [vicadmin]=""
        )
    elif [ "vmware/vic-product" == "${REPO}" ]
    then
        components+=(
            [dinv]="The Docker-in-VIC container image"
            [fileserver]="The Getting Started page and associated fileserver"
            [initialization]="The [re-]initialization process for the OVA"
            [ova]="The build process for the OVA itself"
            [systemd]="The systemd units packaged into the OVA"
            [upgrade]="The automated upgrade script"
        )
    elif [ "vmware/vic-tasks" == "${REPO}" ]
    then
        # The tasks repo doesn't have components
        components=()
    elif [ "vmware/vic-tools" == "${REPO}" ]
    then
        components+=(
            [image_downstream]="The downstream trigger image"
            [image_integration]="The generic integration image"
            [image_passrate]="The passrate calculation image"
            [gandalf]="The gandalf slack bot"
            [robot]="Shared robot functionality"
        )
    elif [ "vmware/vic-ui" == "${REPO}" ]
    then
        components+=(
            [plugin_flex]="The plugin for the vSphere Flex client"
            [plugin_h5c]="The plugin for the vSphere HTML5 client"
            [scripts]="Scripts related to plugin lifecycle"
            [service]="The Java backend service"
       )
    fi

    merge "component" components "${assigned_colors[component]}"
}

merge-commitments () {
    declare -A commitments
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    commitments=(
        [customer]="Affects a commitment made to a customer"
        [release]="Affects a release scope commitment"
        [roadmap]="Affects an engineering roadmap commitment"
        [other]="Affects another type of commitment"
    )

    merge "commitment" commitments "${assigned_colors[commitment]}"
}

merge-impacts () {
    declare -A impacts
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    impacts=(
        [doc_community]="Requires changes to documentation about contributing to the product and interacting with the team"
        [doc_design]="Requires changes to documentation about the design of the product"
        [doc_kb]="Requires creation of or changes to an official knowledge base article"
        [doc_note]="Requires creation of or changes to an official release note"
        [doc_user]="Requires changes to official user documentation"
        [test_integration]="Requires creation of or changes to an integration test"
        [test_scenario]="Requires creation of or changes to a scenario test"
    )

    if [ "vmware/vic" == "${REPO}" ]
    then
        impacts+=(
            [test_integration_enable]="The test is associated with a disabled integration test"
            [test_scenario_enable]="The test is associated with a disabled scenario test"
        )
    fi

    merge "impact" impacts "${assigned_colors[impact]}"
}

merge-kinds () {
    declare -A kinds
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    kinds=(
        [debt]="Problems that increase the cost of other work"
        [defect]="Behavior that is inconsistent with what's intended"
        [defect_performance]="Behavior that is functionally correct, but performs worse than intended"
        [defect_regression]="Changed behavior that is inconsistent with what's intended"
        [defect_security]="A flaw or weakness that could lead to a violation of security policy"
        [enhancement]="Behavior that was intended, but we want to make better"
        [feature]="New functionality you could include in marketing material"
        [task]="Work not related to changing the functionality of the product"
        [question]="A request for information"
        [investigation]="A scoped effort to learn the answers to a set of questions which may include prototyping"
    )

    merge "kind" kinds "${assigned_colors[kind]}"
}

merge-resolutions () {
    declare -A resolutions
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    resolutions=(
        [duplicate]="Another issue exists for this issue"
        [incomplete]="Insufficint information is available to address this issue"
        [invalid]="The issue is intended behavior or otherwise invalid"
        [will-not-fix]="This issue is valid, but will not be fixed"
    )

    merge "resolution" resolutions "${assigned_colors[resolution]}"
}

merge-sources () {
    declare -A sources
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    sources=(
        [ci]="Found via a continuous integration failure"
        [customer]="Reported by a customer, directly or via an intermediary"
        [dogfooding]="Found via a dogfooding activity"
        [longevity]="Found via a longevity failure"
        [nightly]="Found via a nightly failure"
        [system-test]="Reported by the system testing team"
        [performance]="Reported by the performance testing team"
    )

    merge "source" sources "${assigned_colors[source]}"
}

merge-status () {
    declare -A statuses
    # The array is passed by name at the end of this function
    # shellcheck disable=SC2034
    statuses=(
        [need-info]="Additional information is needed to make progress"
        [needs-attention]="The issue needs to be discussed by the team"
        [needs-estimation]="The issue needs to be estimated by the team"
        [needs-triage]="The issue needs to be evaluated and metadata updated"
    )

    merge "status" statuses "${assigned_colors[status]}"
}

merge-all () {
    merge-oneoff
    merge-severity
    merge-products
    merge-areas
    merge-components
    merge-commitments
    merge-impacts
    merge-kinds
    merge-resolutions
    merge-sources
    merge-status
}

merge-all

