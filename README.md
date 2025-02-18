# OSINTARCHIVE
A wrapper for Wayback CDX that allows to passively enumerate website endpoints based on snapshot/crawl history.

```
Query the Wayback CDX Server (defaults: limit=10000, collapse=urlkey, fl=original)
Example dork: example.com/*
```

[https://archive.org/developers/wayback-cdx-server.html](https://archive.org/developers/wayback-cdx-server.html)

### osintarchive.ps1
Wrapper written in PowerShell to use on Windows

```powershell
.\osintarchive.ps1 -dork example.com/*
```

### osintarchive.sh
Wrapper written in Bash.

```bash
bash osintarchive.sh -h # display help
bash osintarchive.sh example.com/*
```

### osintarchive.py
Wrapper written in Python.

```bash
python3 osintarchive.py -h # display help
python3 osintarchive.py example.com/*
```

