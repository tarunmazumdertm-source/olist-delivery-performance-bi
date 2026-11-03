# Data Provenance and Source Notes

## Dataset identity

- **Dataset:** Brazilian E-Commerce Public Dataset by Olist
- **Provider / origin:** Olist, a Brazilian e-commerce marketplace
- **Distribution platform:** Kaggle
- **Source URL:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- **Geographic scope:** Brazil
- **Overall period stated in source documentation:** 2016–2018
- **Format:** Nine CSV files
- **Data type:** Real-world, anonymised relational e-commerce data; it is not synthetic.

## Provenance path

Olist → published on Kaggle → downloaded by the project team → original CSV files retained in the project's local `02_data_acquisition/raw_data/` folder.

Monica's documentation identifies the original uploaded files as being in the `Raw_Datasets` folder in the BI Project - Group 05 Google Drive. Her workbook also provides the file-level inventory in `DATA_SOURCE_INVENTORY.csv`.

## Licence and use notes recorded in the source documentation

- **Licence stated:** Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).
- **Licence URL:** https://creativecommons.org/licenses/by-nc-sa/4.0/
- Monica's workbook describes the intended use as non-commercial academic analysis with attribution, and says adapted material should be shared under the same licence.
- Review the licence terms before redistributing the dataset or adapted material. This project note is a record of the information in the supplied workbook, not legal advice.

## Privacy note

The source documentation describes the data as anonymised. Anonymisation should not be treated as proof that every possible privacy risk is eliminated. Do not attempt to identify individuals or combine the data with external information to do so.

## Relationship to the project's analysis period

The source documentation describes the dataset's overall period as 2016–2018. The GR05 project proposal specifies an analysis scope of orders from **January 2017 through August 2018**. The team should apply and document this project-specific filter during profiling and analysis, rather than assuming that every source row falls inside that period.

## File counts and validation status

The nine filenames, record counts, column counts and file sizes in `DATA_SOURCE_INVENTORY.csv` are transcribed from Monica's supplied `Data Source Documentation.xlsx`. They are source-reported values and have **not yet been independently validated against the local CSV files**. Aimen's data profiling should confirm actual row and column counts, missing values, duplicates, key fields and relationships.

## Storage and version control

- Keep the original CSV files under `02_data_acquisition/raw_data/` for local work.
- The repository `.gitignore` excludes files in this folder. This is intentional because the repository is public and the raw files do not need to be committed for the team to review the project documentation.
- Commit this provenance note, the inventory and the source documentation workbook only after confirming the workbook contains no information that should remain private.
- Preserve original source files unchanged. Put cleaned or transformed outputs in a separate, clearly named location and document the steps used to create them.
