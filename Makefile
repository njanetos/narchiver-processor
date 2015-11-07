MARKETS = abraxas agora blackbank dream evolution hydra marketplace nucleus silkroad

# Unzip everything

raw:
	@./scripts/run_script.sh unzip_raw

# Sort contents by site

raw_by_site/%: raw
	@./scripts/run_script.sh sort_marketplace_$* # | tee logs/sort_marketplace_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Sorting raw by site" "$*" || true

raw_by_site: raw $(patsubst %,raw_by_site/%,$(MARKETS))
	@./scripts/push.sh "Sorted raw by site" "Complete" || true

# Test dataset

raw_zipped_test.zip: raw
	@./scripts/generate_test_dataset.sh # | tee logs/generate_test_dataset_`date +"%m-%d-%Y-%T"`.log

# Clean listings
clean_listings/%.db: raw_by_site/%
	@./scripts/run_script.sh clean_listings_$* # | tee logs/clean_listings_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Cleaning listings" "$*" || true

clean_listings: $(MARKETS:%=clean_listings/%.db)
	@./scripts/push.sh "Cleaned listings" "Complete" || true

# Aggregate listings
aggregate_listings/%.db: clean_listings/%.db
	@./scripts/run_script.sh aggregate_listings_$* # | tee logs/aggregate_listings_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Aggregating listings" "$*" || true

aggregate_listings: $(MARKETS:%=aggregate_listings/%.db)
	@./scripts/push.sh "Aggregated listings" "Complete" || true

# Graph stuff
graphs_%: aggregate_listings/%.db
	@./scripts/run_script.sh graphs $*

graphs: $(MARKETS:%=graphs_%)

sense: clean_listings aggregate_listings graphs

clean:
	rm -rf raw
	rm -rf raw_by_site
	rm -rf clean_listings
	rm -rf clean_categories
	rm -rf aggregate_listings
	rm -rf plots
