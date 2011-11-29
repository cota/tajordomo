#!/bin/bash

for file in *.mail
do
	git send-email --from="Emilio G. Cota <cota@cs.columbia.edu>" \
		--cc="Emilio G. Cota <cota@cs.columbia.edu>"  \
		--smtp-server-option="--account=columbia" \
		--to-cmd="./tocmd.sh" \
		--no-chain-reply-to \
		--quiet \
		$file
done
