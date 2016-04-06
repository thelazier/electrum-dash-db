#!/bin/bash
blocks=$(/home/electrum/bin/run_electrum_dash_server getinfo |jq .blocks)
if [[ $blocks == "" ]]; then
  echo Not found electrum running , please check.
  exit 1
fi
date=$(date -u)
date_fmt=$(date -u +%Y%m%d)
file=electrum-dash-leveldb-utxo-10000
file_gz=${file}.${date_fmt}.tar.gz
file_sha256=${file_gz}.sha256
prevLinks=`head links.md`
header=`cat header.md`
footer=`cat footer.md`
skipping=`grep $file_gz links.md |wc -l`
if [[ $skillping > 0 ]]; then
  echo Today is archived.
  exit 0
fi
# archive
tar -zcvf $file_gz $file/.
sha256sum $file_gz > $file_sha256
size_gz=$(ls -lh $file_gz |awk -F" " '{ print $5}')
url_gz=$(curl --upload-file $file_gz https://transfer.sh/$file_gz)
if [[ $url_gz == "" ]]; then
  echo Upload $file_gz failed..
  exit 1
fi
url_sha256=$(curl --upload-file $file_sha256 https://transfer.sh/$file_sha256)
if [[ $url_sha256 == "" ]]; then
  echo Upload $file_sha256 failed..
  exit 1
fi
newLinks="Block $blocks: $date [$file_gz]($url_gz) ($size_gz) [SHA256]($url_sha256)\n\n$prevLinks"
echo -e "$newLinks" > links.md
rm $file_gz $file_sha256 
#construct README.md
echo -e "$header\n\n####For mainnet:\n\n$newLinks\n\n$footer" > README.md
# Push
git add *.md
git commit -m "$date - autoupdate"
git push
