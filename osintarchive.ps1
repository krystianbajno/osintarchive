param(
    [Parameter(Mandatory=$true)]
    [string]$dork,

    [ValidateSet("exact", "prefix", "host", "domain")]
    [string]$matchType,
    [ValidateSet("json", "text")]
    [string]$output,
    [string]$fl = "original",

    [int]$limit = 10000,
    [int]$offset,
    [int]$page,
    [int]$pageSize,
    [switch]$showNumPages,
    [switch]$showPagedIndex,

    [string]$fromDate,
    [string]$toDate,

    [string[]]$filter,
    [string[]]$collapse = @("urlkey"),

    [switch]$fastLatest,
    [switch]$showResumeKey,
    [string]$resumeKey,
    [switch]$showDupeCount,
    [switch]$showSkipCount,
    [switch]$lastSkipTimestamp,

    [string]$cookie
)

$baseUrl = "http://web.archive.org/cdx/search/cdx"

$params = @{
    "url"   = $dork
    "limit" = $limit
    "fl"    = $fl
}

if ($matchType)            { $params["matchType"]    = $matchType }
if ($output)               { $params["output"]       = $output }
if ($offset)               { $params["offset"]       = $offset }
if ($page -ne $null)       { $params["page"]         = $page }
if ($pageSize -ne $null)   { $params["pageSize"]     = $pageSize }
if ($showNumPages.IsPresent)   { $params["showNumPages"] = "true" }
if ($showPagedIndex.IsPresent) { $params["showPagedIndex"] = "true" }
if ($fromDate)             { $params["from"]         = $fromDate }
if ($toDate)               { $params["to"]           = $toDate }
if ($filter)               { $params["filter"]       = $filter }
if ($collapse)             { $params["collapse"]     = $collapse }
if ($fastLatest.IsPresent) { $params["fastLatest"]   = "true" }
if ($showResumeKey.IsPresent){ $params["showResumeKey"] = "true" }
if ($resumeKey)            { $params["resumeKey"]    = $resumeKey }
if ($showDupeCount.IsPresent){ $params["showDupeCount"] = "true" }
if ($showSkipCount.IsPresent){ $params["showSkipCount"] = "true" }
if ($lastSkipTimestamp.IsPresent){ $params["lastSkipTimestamp"] = "true" }

$query = ($params.GetEnumerator() | ForEach-Object {
    if ($_.Value -is [System.Array]) {
        $_.Value | ForEach-Object { "$($_.Key)=" + [uri]::EscapeDataString($_) }
    } else {
        "$($_.Key)=" + [uri]::EscapeDataString($_.Value.ToString())
    }
}) -join "&"

$uri = "$baseUrl?$query"

Write-Host "Query URL:"
Write-Host $uri

$webOptions = @{}
if ($cookie) {
    $webOptions["Headers"] = @{ "Cookie" = $cookie }
}

$response = Invoke-WebRequest -Uri $uri @webOptions

$response.Content
