#!/usr/bin/env bash
# Download an APK: try apkeep, then apkmirror-downloader, then archive.org.
# Usage: ./dl-apk.sh <package-id> <apkmirror-url> <archive-url> <output> [version]
#   package-id:    e.g. com.instagram.android
#   apkmirror-url: https://www.apkmirror.com/apk/<org>/<repo>  (empty string to skip this fallback)
#   archive-url:   e.g. https://archive.org/download/jhc-apks/apks/com.instagram.android (empty to skip)
#   output:        exact file path to write the apk to; a split bundle is written to "<output>.apkm" instead
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

if apkeep -a "${pkg}${version:+@$version}" -d apk-pure "$scratch"; then
	f=$(find "$scratch" -maxdepth 1 -type f | head -1)
	if [ -n "$f" ]; then
		place "$f"
		pr "Downloaded '$pkg' via apkeep"
		exit 0
	fi
fi
epr "Could not download '$pkg' via apkeep, falling back to apkmirror-downloader"

if [ -n "$apkmirror_url" ]; then
	# org/repo are the last two path segments of https://www.apkmirror.com/apk/<org>/<repo>
	IFS='/' read -r -a parts <<<"${apkmirror_url%/}"
	org=${parts[-2]}
	repo=${parts[-1]}
	if apkmd --org "$org" --repo "$repo" ${version:+--version "$version"} --outDir "$scratch"; then
		f=$(find "$scratch" -maxdepth 1 -type f | head -1)
		if [ -n "$f" ]; then
			place "$f"
			pr "Downloaded '$pkg' via apkmirror-downloader"
			exit 0
		fi
	fi
	epr "Could not download '$pkg' via apkmirror-downloader, falling back to archive.org"
else
	epr "No apkmirror-url given for '$pkg', skipping apkmirror-downloader"
fi

if [ -z "$archive_url" ]; then
	epr "No archive-url given for '$pkg'"
	exit 1
fi

# pick the file matching $version (or the newest listed entry if no version given)
listing=$(curl -fsSL "$archive_url" | sed -n 's;^<a href="\([^"]*\)"[^>]*>.*;\1;p')
file=$([ -n "$version" ] && grep -m1 -- "-${version}-" <<<"$listing" || tail -n1 <<<"$listing")
if [ -z "$file" ]; then
	epr "Could not find '$pkg' in archive.org"
	exit 1
fi

curl -fsSL -o "$scratch/$file" "${archive_url%/}/$file"
place "$scratch/$file"
pr "Downloaded '$pkg' via archive.org ($file)"
