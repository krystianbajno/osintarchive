#!/usr/bin/env python3

import argparse
import urllib.parse
import urllib.request
import os
import sys
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
import urllib.error

CDX_API_URL = "http://web.archive.org/cdx/search/cdx"

def query_wayback_all(url):
    params = {
        "url": url,
        "output": "json",
        "fl": "timestamp,original",
        "filter": "statuscode:200"
    }
    query_string = urllib.parse.urlencode(params)
    full_url = f"{CDX_API_URL}?{query_string}"

    print(f"Querying Wayback CDX API:\n{full_url}")

    try:
        with urllib.request.urlopen(full_url) as response:
            body = response.read().decode('utf-8')
            data = json.loads(body)
            return data[1:] if len(data) > 1 else []
    except Exception as e:
        print("Error querying Wayback:", e)
        return []

def download_wayback_capture_raw(timestamp, original_url, download_dir):
    wayback_raw_url = f"https://web.archive.org/web/{timestamp}id_/{original_url}"

    try:
        os.makedirs(download_dir, exist_ok=True)
        filename = f"{timestamp}_{os.path.basename(urllib.parse.urlparse(original_url).path)}"
        if not filename or filename.endswith('_'):
            filename += "file"

        dest_path = os.path.join(download_dir, filename)
        print(f"Downloading raw file: {wayback_raw_url} -> {dest_path}")

        head_req = urllib.request.Request(wayback_raw_url, method='HEAD')
        with urllib.request.urlopen(head_req) as head_resp:
            content_type = head_resp.headers.get('Content-Type', '')
            if 'text/html' in content_type.lower():
                print(f"Skipping {wayback_raw_url}: Content-Type is HTML (likely error page)")
                return

        urllib.request.urlretrieve(wayback_raw_url, dest_path)
        print(f"Saved raw file to: {dest_path}")

    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"Not found (404): {wayback_raw_url}")
        else:
            print(f"HTTP Error {e.code} for {wayback_raw_url}")
    except Exception as e:
        print(f"Failed to download {wayback_raw_url}: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Download all archived captures (raw files) from Wayback Machine for given URL(s)."
    )
    parser.add_argument("url", nargs="?", help="The original URL to look up in Wayback Machine.")
    parser.add_argument("--url-file", help="File containing URLs to look up, one per line.")
    parser.add_argument("--download-dir", default="downloads",
                        help="Directory to save downloaded files (default: downloads/)")
    parser.add_argument("--threads", type=int, default=8,
                        help="Number of concurrent download threads (default: 8)")
    args = parser.parse_args()

    urls = []

    if args.url:
        urls.append(args.url)
    elif args.url_file:
        try:
            with open(args.url_file, 'r') as f:
                urls = [line.strip() for line in f if line.strip()]
        except Exception as e:
            print(f"Failed to read URL file: {e}")
            return
    else:
        if sys.stdin.isatty():
            print("No URLs provided via argument, --url-file, or stdin.")
            return
        print("Reading URLs from stdin...")
        for line in sys.stdin:
            line = line.strip()
            if line:
                urls.append(line)

    if not urls:
        print("No URLs to process.")
        return

    for url in urls:
        print(f"\nProcessing URL: {url}")
        results = query_wayback_all(url)
        if not results:
            print(f"No archived captures found for {url}.")
            continue

        print(f"Found {len(results)} captures for {url}.")

        with ThreadPoolExecutor(max_workers=args.threads) as executor:
            futures = []
            for timestamp, original_url in results:
                futures.append(
                    executor.submit(download_wayback_capture_raw, timestamp, original_url, args.download_dir)
                )
            for future in as_completed(futures):
                try:
                    future.result()
                except Exception as e:
                    print(f"Error during download: {e}")

if __name__ == "__main__":
    main()
