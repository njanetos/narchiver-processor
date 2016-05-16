MARKETS = abraxas agora blackbank dream evolution hydra marketplace nucleus silkroad

# Unzip everything
raw: raw_zipped
	@./scripts/run_script.sh unzip_raw

# Sort contents by site
# Sorts into folders labeled by the site name
raw_by_site/%: raw
	@./scripts/run_script.sh sort_marketplace_$* | tee logs/sort_marketplace_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Sorting raw by site" "$*" || true

raw_by_site: raw $(patsubst %,raw_by_site/%,$(MARKETS))
	@./scripts/push.sh "Sorted raw by site" "Complete" || true

# Constructs a test archive by pulling several thousand pages randomly out and
# zipping them
raw_zipped_test.zip: raw
	@./scripts/generate_test_dataset.sh | tee logs/generate_test_dataset_`date +"%m-%d-%Y-%T"`.log

# Extracts information like the title, and price, and puts it, stripped of
# HTML, into a sqlite database.
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

# Goes through the clean_listings database, and extracts numerical data from it
extract_data_listings/%.db: clean_listings/%.db
	@./scripts/run_script.sh extract_data_listings_$* | tee logs/extract_data_listings_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Aggregating listings" "$*" || true

extract_data_listings: $(MARKETS:%=extract_data_listings/%.db)
	@./scripts/push.sh "Aggregated listings" "Complete" || true

extract_data_vendors/%.db: clean_vendors/%.db
	@./scripts/run_script.sh extract_data_vendors_$* | tee logs/extract_data_vendors_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Aggregating vendors" "$*" || true

extract_data_vendors: $(MARKETS:%=extract_data_vendors/%.db)
	@./scripts/push.sh "Aggregated vendors" "Complete" || true

# Combined the information from extract_data_listings and extract_data_vendors
# into one database, and performs validation checks
combined_market/%.db: extract_data_vendors/%.db extract_data_listings/%.db
	@./scripts/run_script.sh combine_market_$* | tee logs/combined_market_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Combining market" "$*" || true

combined_market: $(MARKETS:%=combined_market/%.db)
	@./scripts/push.sh "Combined markets" "Complete" || true

# Constructs final-use data
public_data/%-reviews.csv: combined_market/%.db
	@./scripts/run_script.sh public_data_$* | tee public_data_$*_`date +"%m-%d-%Y-%T"`.log
	@./scripts/push.sh "Constructing public data" "$*" || true

public_data: $(MARKETS:%=balanced_panel/%.csv)
	@./scripts/push.sh "Public data" "Complete" || true

# Automagically builds the codebooks for the various databases
documentation:
	@find -name *.db -exec ./scripts/run_script.sh autodocument {} \;;

# Global build target
sense: clean_listings extract_data_listings clean_vendors extract_data_vendors combined_market balanced_panel

clean:
	find -name *.db -delete
