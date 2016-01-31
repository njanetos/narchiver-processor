MARKETS = abraxas agora blackbank dream evolution hydra marketplace nucleus silkroad

# Unzip everything

raw:
	@./scripts/run_script.sh unzip_raw

# Sort contents by site

raw_by_site/%: raw
	@./scripts/run_script.sh sort_marketplace_$* | tee logs/sort_marketplace_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Sorting raw by site" "$*" || true

raw_by_site: raw $(patsubst %,raw_by_site/%,$(MARKETS))
	@./scripts/push.sh "Sorted raw by site" "Complete" || true

# Test dataset

raw_zipped_test.zip: raw
	@./scripts/generate_test_dataset.sh | tee logs/generate_test_dataset_`date +"%m-%d-%Y-%T"`.log

# Clean listings
clean_listings/%.db: raw_by_site/%
	@./scripts/run_script.sh clean_listings_$* | tee logs/clean_listings_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Cleaning listings" "$*" || true

clean_listings: $(MARKETS:%=clean_listings/%.db)
	@./scripts/push.sh "Cleaned listings" "Complete" || true

clean_vendors/%.db: raw_by_site/%
	@./scripts/run_script.sh clean_vendors_$* | tee logs/clean_listings_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Cleaning listings" "$*" || true

clean_vendors: $(MARKETS:%=clean_vendors/%.db)
	@./scripts/push.sh "Cleaned listings" "Complete" || true

# Aggregate listings
extract_data_listings/%.db: clean_listings/%.db
	@./scripts/run_script.sh extract_data_listings_$* | tee logs/extract_data_listings_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Aggregating listings" "$*" || true

extract_data_listings: $(MARKETS:%=extract_data_listings/%.db)
	@./scripts/push.sh "Aggregated listings" "Complete" || true

# Aggregate vendors
extract_data_vendors/%.db: clean_vendors/%.db
	@./scripts/run_script.sh extract_data_vendors_$* | tee logs/extract_data_vendors_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Aggregating vendors" "$*" || true

extract_data_vendors: $(MARKETS:%=extract_data_vendors/%.db)
	@./scripts/push.sh "Aggregated vendors" "Complete" || true

# Combine everything together
combined_market/%.db: extract_data_vendors/%.db extract_data_listings/%.db
	@./scripts/run_script.sh combine_market_$* | tee logs/combined_market_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Combining market" "$*" || true

combined_market: $(MARKETS:%=combined_market/%.db)
	@./scripts/push.sh "Combined markets" "Complete" || true

# Construct balanced panel data
balanced_panel/%.csv: combined_market/%.db
	@./scripts/run_script.sh balanced_panel_$* | tee logs/balanced_panel_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Constructing balanced panel data" "$*" || true

balanced_panel: $(MARKETS:%=balanced_panel/%.csv)
	@./scripts/push.sh "Balanced panel dataset" "Complete" || true

documentation:
	@find -name *.db -exec ./scripts/run_script.sh autodocument {} \;;

sense: clean_listings extract_data_listings clean_vendors extract_data_vendors combined_market

clean:
	find -name *.db -delete
