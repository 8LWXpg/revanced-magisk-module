# Config

## All Options:

There exists an example below with all defaults shown and all the keys explicitly set.  
**All keys are optional** (except download urls) and are assigned to their default values if not set explicitly.  

```toml
parallel-jobs = 1 # amount of cores to use for parallel patching, if not set $(nproc) is used

patches-source = "MorpheApp/morphe-patches"  # where to fetch patches bundle from. default: "MorpheApp/morphe-patches"
cli-source = "MorpheApp/morphe-cli"          # where to fetch cli from. default: "MorpheApp/morphe-cli"
# options like cli-source can also set per app

patches-version = "v2.160.0" # 'latest', 'dev', or a version number. default: "latest"
cli-version = "v5.0.0"       # 'latest', 'dev', or a version number. default: "latest"

[Some-App]
app-name = "SomeApp" # if set, release name becomes SomeApp instead of Some-App. default is same as table name, which is 'Some-App' here.
enabled = true       # whether to build the app. default: true

# 'auto' option gets the latest possible version supported by all the included patches
# 'latest' gets the latest stable without checking patches support. 'beta' gets the latest beta/alpha
# whitespace seperated list of patches to exclude. default: ""
version = "auto"     # 'auto', 'experimental', 'latest' or a version number (e.g. '17.40.41'). default: auto

# optional args to be passed to cli. can be used to set patch options
# multiline strings in the config is supported
patcher-args = """\
  -OdarkThemeBackgroundColor=#FF0F0F0F \
  -Oanother-option=value \
  """

excluded-patches = """\
  'Some Patch' \
  'Some Other Patch' \
  """

included-patches = "'Some Patch'"                          # whitespace seperated list of non-default patches to include. default: ""
exclusive-patches = false                                  # exclude all patches by default. default: false

apkpure-dlurl = "https://apkpure.net/x/com.spotify.music"      # any apkpure app url works; the slug ('x' here) is ignored. supplies the package id and is the last-resort download source (via apkeep), see dl-apk.sh
archive-dlurl = "https://archive.org/download/jhc-apks/apks/com.spotify.music" # optional, tried first
apkmirror-dlurl = "https://www.apkmirror.com/apk/inc/app"  # optional, tried second (via apkmirror-downloader)
```
