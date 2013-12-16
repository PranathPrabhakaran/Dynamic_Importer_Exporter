Dynamic_Importer_Exporter
=========================

Outline:
Config file containing the model for the stock parameter and format of the file is set. This would help altering the model in the future without any changes to the code. In the case of formats, extra code would be needed to added to accomodate the different formats other than currently given csv and json.

The class stock is created dynamically using the model. The formats are set as specified in the Config file and the csv and jsin can be interchanged by only making changes in the Config file.

Rules are set in the class Stock so that the instances can be checked as soon as they are fed to the class raising an error and pointing to the line in the data file.

Each Row/Record read from the data files (currently csv or json file) is added as instance variables to instance of class Stock and stored in the class array variable(@@array) after checking for the rules mentioned.

Assumptions:
1. Assumed that in the future parameters like modifiers with multiple alterations are named as (modifier_<number>_<sub category>) as current.
2. Assumed data is to be appended while exporting to csv. Can be changed to write mode in the write method.
3. Assumed only one process occurs at a time i.e either import or export
