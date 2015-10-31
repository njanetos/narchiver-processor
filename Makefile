MARKETS = abraxas agora blackbank dream evolution hydra marketplace nucleus silkroad

raw: raw.zip scripts/unzip_raw.sh
	./scripts/unzip_raw.sh | tee logs/raw`date +"%m-%d-%Y-%T"`.log

raw_by_site/%: raw
	./scripts/sort_marketplace.sh $* | tee logs/raw_by_site_%`date +"%m-%d-%Y-%T"`.log 

raw_by_site: $(patsubst %,raw_by_site/%,$(MARKETS))
