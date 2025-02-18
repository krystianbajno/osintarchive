#!/bin/bash

set -e

usage() {
    cat <<EOF
Usage: $0 <dork> [options]

Required:
  <dork>                   URL query (e.g. example.com/*)

Optional (defaults in parentheses):
  --matchType <matchType>         Match type: exact, prefix, host, or domain
  --output <json|text>            Output format
  --fl <fields>                   Comma-separated fields list (default: original)
  --limit <number>                Limit number of results (default: 10000)
  --offset <number>               Skip first N results
  --page <number>                 Pagination page number
  --pageSize <number>             Pagination page size
  --showNumPages                  Show total number of pages
  --showPagedIndex                Return the raw secondary index
  --from-date <YYYYMMDDhhmmss>      Start date (inclusive)
  --to-date <YYYYMMDDhhmmss>        End date (inclusive)
  --filter <filter>               Filter parameter (can be repeated)
  --collapse <collapse>           Collapse parameter (can be repeated; default: urlkey)
  --fastLatest                    Enable fastLatest mode
  --showResumeKey                 Include resume key if available
  --resumeKey <resumeKey>         Resume key to continue a previous query
  --showDupeCount                 Include duplicate count column
  --showSkipCount                 Include skip count column
  --lastSkipTimestamp             Include last skip timestamp
  --cookie <cookie>               API key cookie (e.g. "cdx-auth-token=API-Key-Secret")
EOF
    exit 1
}

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c hex
  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [a-zA-Z0-9.~_-]) encoded+="$c" ;;
        *) printf -v hex '%%%02X' "'$c"
           encoded+="${hex}"
           ;;
     esac
  done
  echo "$encoded"
}

urlencode() {
  rawurlencode "$1"
}

if [ "$#" -lt 1 ]; then
    usage
fi

dork="$1"
shift

matchType=""
output=""
fl=""
limit=""
offset=""
page=""
pageSize=""
showNumPages=""
showPagedIndex=""
from_date=""
to_date=""
declare -a filter_param
declare -a collapse_param
fastLatest=""
showResumeKey=""
resumeKey=""
showDupeCount=""
showSkipCount=""
lastSkipTimestamp=""
cookie=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --matchType) matchType="$2"; shift 2 ;;
        --output) output="$2"; shift 2 ;;
        --fl) fl="$2"; shift 2 ;;
        --limit) limit="$2"; shift 2 ;;
        --offset) offset="$2"; shift 2 ;;
        --page) page="$2"; shift 2 ;;
        --pageSize) pageSize="$2"; shift 2 ;;
        --showNumPages) showNumPages="true"; shift 1 ;;
        --showPagedIndex) showPagedIndex="true"; shift 1 ;;
        --from-date) from_date="$2"; shift 2 ;;
        --to-date) to_date="$2"; shift 2 ;;
        --filter) filter_param+=("$2"); shift 2 ;;
        --collapse) collapse_param+=("$2"); shift 2 ;;
        --fastLatest) fastLatest="true"; shift 1 ;;
        --showResumeKey) showResumeKey="true"; shift 1 ;;
        --resumeKey) resumeKey="$2"; shift 2 ;;
        --showDupeCount) showDupeCount="true"; shift 1 ;;
        --showSkipCount) showSkipCount="true"; shift 1 ;;
        --lastSkipTimestamp) lastSkipTimestamp="true"; shift 1 ;;
        --cookie) cookie="$2"; shift 2 ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
done

if [ -z "$dork" ]; then
    echo "Error: <dork> is required."
    usage
fi

if [ -z "$limit" ]; then limit=10000; fi
if [ -z "$fl" ]; then fl="original"; fi
if [ ${#collapse_param[@]} -eq 0 ]; then collapse_param+=("urlkey"); fi

base_url="http://web.archive.org/cdx/search/cdx"

query="url=$(urlencode "$dork")"
[ -n "$matchType" ] && query="${query}&matchType=$(urlencode "$matchType")"
[ -n "$output" ] && query="${query}&output=$(urlencode "$output")"
[ -n "$fl" ] && query="${query}&fl=$(urlencode "$fl")"
[ -n "$limit" ] && query="${query}&limit=$limit"
[ -n "$offset" ] && query="${query}&offset=$offset"
[ -n "$page" ] && query="${query}&page=$page"
[ -n "$pageSize" ] && query="${query}&pageSize=$pageSize"
[ -n "$showNumPages" ] && query="${query}&showNumPages=$showNumPages"
[ -n "$showPagedIndex" ] && query="${query}&showPagedIndex=$showPagedIndex"
[ -n "$from_date" ] && query="${query}&from=$(urlencode "$from_date")"
[ -n "$to_date" ] && query="${query}&to=$(urlencode "$to_date")"

for f in "${filter_param[@]}"; do
    query="${query}&filter=$(urlencode "$f")"
done

for c in "${collapse_param[@]}"; do
    query="${query}&collapse=$(urlencode "$c")"
done

[ -n "$fastLatest" ] && query="${query}&fastLatest=$fastLatest"
[ -n "$showResumeKey" ] && query="${query}&showResumeKey=$showResumeKey"
[ -n "$resumeKey" ] && query="${query}&resumeKey=$(urlencode "$resumeKey")"
[ -n "$showDupeCount" ] && query="${query}&showDupeCount=$showDupeCount"
[ -n "$showSkipCount" ] && query="${query}&showSkipCount=$showSkipCount"
[ -n "$lastSkipTimestamp" ] && query="${query}&lastSkipTimestamp=$lastSkipTimestamp"

final_url="${base_url}?${query}"

echo "Query URL:"
echo "$final_url"

if [ -n "$cookie" ]; then
    curl -H "Cookie: $cookie" "$final_url"
else
    curl "$final_url"
fi
