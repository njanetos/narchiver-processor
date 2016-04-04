# Readme

Processing scripts for the Narchiver.

## Usage


Requires a directory `raw_zipped` containing raw narchived zip files. The test dataset, `raw_zipped_test.zip` will be automatically unzipped into `raw_zipped` if `raw_zipped` is not available. `raw_zipped_test.zip` consists of 5000 randomly selected items from the full archives. Support for `git-lfs` must be enabled for the test dataset to be downloaded with the rest of the repository. Otherwise, it may be downloaded manually. The file structure should look like

```
logs/
Makefile
scripts/
raw_zipped/ [optional]
    |- archive[date1].zip
    |- archive[date2].zip
    ...
raw_zipped_test.zip
```

Every operation may be run with the global build target
```{bash}
make sense
```

## Organization / contribution

The data processing pipeline is organized as a tree, encoded in the makefile, with the root node being `raw`. New segments of the pipeline must consist of the following parts:

1. Code in `/scripts` to process the data. The code can be in any language, but should follow the format `[name of segment]_[name of market].[extension]`. For example, the python script to clean up html for the Agora marketplace is called `clean_listings_agora.py`.
1. Two build targets in the Makefile. 
  1. The first build target should allow for multiple markets. It should be named after the thing it produces. Continuing the example above, the build target looks like

    ```{Makefile}
    clean_listings/%.db: raw_by_site/%
	  @./scripts/run_script.sh clean_listings_$* | tee logs/clean_listings_$*_`date +"%m-%d-%Y-%T"`
    ``` 

    This build target indicates that it produces something called `*.db` in the directory `clean_listings`. The actual script to be run is `clean_listings_agora.py`. The `Makefile` is instructed to run `scripts/run_script.sh`, and `clean_listings_&*` is passed on as an argument. The script `run_script.sh` will identify what sort of script it is being passed and run it. If you want to pass arguments to `clean_listings_agora.py` they can be passed as additional arguments to `run_script.sh`. Everything should be timestamped and logged using `tee`, under the name of the script being run, to `logs/`.
  1. The second build target looks like 

    ```{Makefile}
    clean_listings: $(MARKETS:%=clean_listings/%.db)
    ```
    
    It contains all of the first build targets as dependencies, each now indexed by the name of the market. This build target should also be added to the `sense` build target as a dependency,
    
    ```{Makefile}
    sense: [dependency1] [dependency2] ... clean_listings
    ```
  
The reason for organizing it this way is that it exposes every missing piece of the pipeline in an organized way, and reduces hardcoding in the `Makefile`. For example, if I wanted to write a script to extract all the user names from the `abraxas` marketplace, I would write that script, call it `extracted_user_names_abraxas.py`, place it in the scripts folder, then add the two build targets as described above. Then, I could call

```{bash}
make extracted_user_names/abraxas.db
```

In this example, if the global build target is called, then the build target `extracted_user_names` will be recognized as a dependency and called, which includes now, for example, `extracted_user_names/evolution.db` as a dependency, which requires a script called `extracted_user_names_evolution.*` to run. Instead of throwing an error, the system will recognize that there is a missing segment to the pipeline, issue a warning, and move on. Subsequent global builds will re-try the missing segments (and only the missing segments) until the code is written. 

## Script conventions 

1. Every script should output to a temporary file, only moving to the final result at the very end. This way, if a script fails, the Makefile won't mark it as a success. 
2. Processed data is stored at the top level directory in a directory whose name corresponds to the build target.
