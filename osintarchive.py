#!/usr/bin/env python3

import argparse
import urllib.parse
import urllib.request

def main():
    parser = argparse.ArgumentParser(
        description="""Query the Wayback CDX Server (defaults: limit=10000, collapse=urlkey, fl=original)\n
https://archive.org/developers/wayback-cdx-server.html\n
Example dork: example.com/*
"""
    )
    parser.add_argument("dork", help="URL query (e.g. example.com/*)")

    parser.add_argument("--matchType", choices=["exact", "prefix", "host", "domain"],
                        help="Match type: exact (default), prefix, host, or domain")
    parser.add_argument("--output", choices=["json", "text"],
                        help="Output format: json or plain text")
    parser.add_argument("--fl", default="original",
                        help="Comma separated list of fields to return (default: original)")
    parser.add_argument("--limit", type=int, default=10000,
                        help="Limit the number of results (default: 10000)")
    parser.add_argument("--offset", type=int, help="Skip the first N results")
    parser.add_argument("--page", type=int, help="Page number for pagination")
    parser.add_argument("--pageSize", type=int, help="Page size for pagination")
    parser.add_argument("--showNumPages", action="store_true",
                        help="Return the total number of pages (pagination only)")
    parser.add_argument("--showPagedIndex", action="store_true",
                        help="Return the raw secondary index (pagination only)")
    parser.add_argument("--from-date", dest="from_date", metavar="YYYYMMDDhhmmss",
                        help="Start date (inclusive)")
    parser.add_argument("--to-date", dest="to_date", metavar="YYYYMMDDhhmmss",
                        help="End date (inclusive)")
    parser.add_argument("--filter", action="append",
                        help="Filter parameter in the form [!]<field>:<regex> (can be repeated)")
    parser.add_argument("--collapse", action="append", default=["urlkey"],
                        help="Collapse parameter in the form field[:N] (default: urlkey)")
    parser.add_argument("--fastLatest", action="store_true", help="Enable fastLatest mode")
    parser.add_argument("--showResumeKey", action="store_true", help="Include resume key if available")
    parser.add_argument("--resumeKey", help="Resume key to continue a previous query")
    parser.add_argument("--showDupeCount", action="store_true", help="Include duplicate count column")
    parser.add_argument("--showSkipCount", action="store_true", help="Include skip count column")
    parser.add_argument("--lastSkipTimestamp", action="store_true", help="Include last skip timestamp")
    parser.add_argument("--cookie", help="API key cookie (e.g. 'cdx-auth-token=API-Key-Secret')")

    args = parser.parse_args()
    base_url = "http://web.archive.org/cdx/search/cdx"

    params = {
        "url": args.dork,
        "limit": args.limit,
        "fl": args.fl
    }

    direct_mapping = {
        "matchType": "matchType",
        "output": "output",
        "offset": "offset",
        "page": "page",
        "pageSize": "pageSize",
        "from_date": "from",
        "to_date": "to",
        "resumeKey": "resumeKey"
    }
    for arg_attr, param_key in direct_mapping.items():
        value = getattr(args, arg_attr)
        if value is not None:
            params[param_key] = value

    bool_mapping = {
        "showNumPages": "showNumPages",
        "showPagedIndex": "showPagedIndex",
        "fastLatest": "fastLatest",
        "showResumeKey": "showResumeKey",
        "showDupeCount": "showDupeCount",
        "showSkipCount": "showSkipCount",
        "lastSkipTimestamp": "lastSkipTimestamp"
    }
    for arg_attr, param_key in bool_mapping.items():
        if getattr(args, arg_attr):
            params[param_key] = "true"

    list_mapping = {
        "filter": "filter",
        "collapse": "collapse"
    }
    for arg_attr, param_key in list_mapping.items():
        value = getattr(args, arg_attr)
        if value is not None:
            params[param_key] = value

    query_string = urllib.parse.urlencode(params, doseq=True)
    url = base_url + "?" + query_string
    
    print(f"Query URL:\n{url}")

    req = urllib.request.Request(url)
    if args.cookie:
        req.add_header("Cookie", args.cookie)

    try:
        with urllib.request.urlopen(req) as response:
            body = response.read().decode('utf-8')
            print(body)
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    main()
