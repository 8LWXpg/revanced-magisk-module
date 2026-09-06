#!/usr/bin/env bash
# Download an APK: try archive.org, then apkmirror-downloader, then apkeep (apk-pure) last resort.
# Usage: ./dl-apk.sh <package-id> <apkmirror-url> <archive-url> <output> [version]
#   package-id:    e.g. com.instagram.android
#   apkmirror-url: https://www.apkmirror.com/apk/<org>/<repo>  (empty string to skip this source)
#   archive-url:   e.g. https://archive.org/download/jhc-apks/apks/com.instagram.android (empty to skip)
#   output:        exact file path to write the apk to; a split bundle is written to "<output>.apkm" instead
# apk-pure (via apkeep) cannot reliably serve a specific historical version - it may 404 or
# silently return a different build - so it is tried last, as a best-effort fallback only.
set -euo pipefail

pr() { echo -e "\033[0;32m[+] ${1}\033[0m"; }
epr() { echo >&2 -e "\033[0;31m[-] ${1}\033[0m"; }

pkg=${1:?usage: dl-apk.sh <package-id> <apkmirror-url> <archive-url> <output> [version]}
apkmirror_url=${2-}
archive_url=${3-}
output=${4:?usage: dl-apk.sh <package-id> <apkmirror-url> <archive-url> <output> [version]}
version=${5-}

mkdir -p "$(dirname "$output")"
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# move whatever the downloader produced into place; split bundles (.apkm/.xapk) go to "$output.apkm"
place() {
	case "$1" in
	*.apkm | *.xapk) mv -f "$1" "${output}.apkm" ;;
	*) mv -f "$1" "$output" ;;
	esac
}

if [ -n "$archive_url" ]; then
	# pick the file matching $version, or the newest listed entry if no version was requested;
	# if a version WAS requested and isn't listed, file stays empty rather than silently
	# substituting the wrong version. A missing/404 archive listing also falls through below.
	listing=$(curl -fsSL "$archive_url" | sed -n 's;^<a href="\([^"]*\)"[^>]*>.*;\1;p') || listing=""
	if [ -n "$version" ]; then
		candidates=$(grep -- "-${version}-" <<<"$listing") || candidates=""
	else
		# newest version = last listed; keep every arch variant of it for the arch pick below
		newest=$(tail -n1 <<<"$listing" | sed -n 's;.*-\([0-9][0-9.]*\)-.*;\1;p') || newest=""
		candidates=$([ -n "$newest" ] && grep -- "-${newest}-" <<<"$listing" || tail -n1 <<<"$listing") || candidates=""
	fi
	# archive.org only carries "-arm64-v8a.<ext>" or "-all.<ext>" builds; take those, skip "-arm-v7a." etc.
	file=$(grep -m1 -- '-arm64-v8a\.' <<<"$candidates") ||
		file=$(grep -m1 -- '-all\.' <<<"$candidates") || file=""
	if [ -n "$file" ] && curl -fsSL -o "$scratch/$file" "${archive_url%/}/$file"; then
		place "$scratch/$file"
		pr "Downloaded '$pkg' via archive.org ($file)"
		exit 0
	fi
	epr "Could not download '$pkg' from archive.org, falling back to apkmirror-downloader"
else
	epr "No archive-url given for '$pkg', skipping archive.org"
fi

if [ -n "$apkmirror_url" ]; then
	# org/repo are the last two path segments of https://www.apkmirror.com/apk/<org>/<repo>
	IFS='/' read -r -a parts <<<"${apkmirror_url%/}"
	org=${parts[-2]}
	repo=${parts[-1]}
	if apkmd download "$org" "$repo" ${version:+--version "$version"} --outdir "$scratch"; then
		f=$(find "$scratch" -maxdepth 1 -type f | head -1)
		if [ -n "$f" ]; then
			place "$f"
			pr "Downloaded '$pkg' via apkmirror-downloader"
			exit 0
		fi
	fi
	epr "Could not download '$pkg' via apkmirror-downloader, falling back to apk-pure (apkeep)"
else
	epr "No apkmirror-url given for '$pkg', skipping apkmirror-downloader"
fi

if apkeep -a "${pkg}${version:+@$version}" -d apk-pure "$scratch"; then
	f=$(find "$scratch" -maxdepth 1 -type f | head -1)
	if [ -n "$f" ]; then
		place "$f"
		pr "Downloaded '$pkg' via apk-pure (apkeep)"
		exit 0
	fi
fi
epr "Could not download '$pkg' from any source"
exit 1
