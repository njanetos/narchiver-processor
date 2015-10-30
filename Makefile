raw: raw.zip
	./scripts/unzip_raw.sh > logs/raw`date +"%m-%d-%Y-%T"`.log

raw_categories: raw
	./scripts/move_categories.sh > logs/raw_categories`date +"%m-%d-%Y-%T"`.log
