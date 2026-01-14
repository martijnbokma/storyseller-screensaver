#!/usr/bin/env bash
set -euo pipefail

# Update VERSION file based on latest git tag

get_latest_version() {
    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    if [[ -z "$latest_tag" ]]; then
        echo "1.0.0"
    else
        echo "$latest_tag" | sed 's/^v//'
    fi
}

update_version_file() {
    local current_version
    current_version=$(get_latest_version)

    echo "$current_version" > VERSION
    echo "Updated VERSION file to: $current_version"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_version_file
fi