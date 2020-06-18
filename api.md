# apis:
- PrintTable(<lua table>)
	- print the k and v of a table.
- core.debug([debugLevel], ...)
	- output debug log
	- without debuglevel, the logdefault flag determine if this works.
- code.debuglevel(<debuglevel>, [logdefault])
	- set debug level and logdefault flag.
	- set logdefault to -1 means default will be ignored, 1 or 0 will be loged.

