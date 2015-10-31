MARKETS = abraxas agora blackbank dream evolution hydra marketplace nucleus silkroad

# Unzip everything

raw: raw.zip
	@./scripts/run_script.sh unzip_raw # | tee logs/raw`date +"%m-%d-%Y-%T"`.log

# Sort contents by site

raw_by_site/%: raw
	@./scripts/run_script.sh sort_marketplace $* | tee logs/raw_by_site_$*_`date +"%m-%d-%Y-%T"`.log

raw_by_site: $(patsubst %,raw_by_site/%,$(MARKETS))

# Extract categories

categories/%: raw_by_site/%
	@./scripts/run_script.sh pull_categories_$* | tee logs/categories_$*_`date +"%m-%d-%Y-%T"`.log

categories: $(patsubst %,categories/%,$(MARKETS))
