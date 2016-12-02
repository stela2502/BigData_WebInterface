## Here I want to use the tool while creating some useful javascript applets for this page. 
## this line will create some outfiles, that I later on can use as infiles...
PMID25158935 <- NGSexpressionSet( PMID25158935exp, PMID25158935samples,  name='PMID25158935', namecol='Sample', namerow= 'GeneID', outpath = '../../tmp/')

Error in eval(expr, envir, enclos) : 
  could not find function "NGSexpressionSet"
library(StefansExpressionSet)

Loading required package: reshape2
Loading required package: stringr
Loading required package: RSvgDevice
Loading required package: rgl
Loading required package: gplots

Attaching package: ‘gplots’

The following object is masked from ‘package:stats’:

    lowess

Loading required package: RFclust.SGE
Loading required package: MASS
Loading required package: cluster
Loading required package: survival
Loading required package: randomForest
randomForest 4.6-12
Type rfNews() to see new features/changes/bug fixes.
Loading required package: Hmisc
Loading required package: lattice
Loading required package: Formula
Loading required package: ggplot2

Attaching package: ‘ggplot2’

The following object is masked from ‘package:randomForest’:

    margin


Attaching package: ‘Hmisc’

The following object is masked from ‘package:randomForest’:

    combine

The following objects are masked from ‘package:base’:

    format.pval, round.POSIXt, trunc.POSIXt, units

PMID25158935 <- NGSexpressionSet( PMID25158935exp, PMID25158935samples,  name='PMID25158935', namecol='Sample', namerow= 'GeneID', outpath = '')

## Yes the outfiles have been created!
files <- c('PMID25158935_Sample_Description.xls', 'PMID25158935_DataValues.xls' )
## by
## Just to see whether it loads again...
print (PMID25158935)
An object of class NGSexpressionSet 
named  PMID25158935 
with 24062 genes and 15  samples. 
Annotation datasets (24062,2): 'GeneID', 'Length'   
Sample annotation (15,20): 'Source.Name', 'Comment.ENA_SAMPLE', 'Provider', 'Characteristics.organism', 'Characteristics.strain', 'Characteristics.cell.type', 'Material.Type.1', 'Comment.LIBRARY_LAYOUT', 'Comment.LIBRARY_SOURCE', 'Comment.LIBRARY_STRATEGY', 'Comment.LIBRARY_SELECTION', 'Performer', 'GroupName', 'Technology.Type', 'Comment.ENA_EXPERIMENT', 'Scan.Name', 'Sample', 'Comment.FASTQ_URI', 'Factor.Value.cell.type', 'bam filename'   
system( 'cp * ../data')
## Here I want to use the tool while creating some useful javascript applets for this page. 

blablabla <- NGSexpressionSet( 
	"../data/PMID25158935_DataValues.xls",
	"../data/PMID25158935_Sample_Description.xls",
	name="you object name",
 	namecol="filename",
 	namerow= "GeneID"
 )
Error in eval(expr, envir, enclos) : 
  could not find function "NGSexpressionSet"
library(StefansExpressionSet)
Loading required package: reshape2
Loading required package: stringr
Loading required package: RSvgDevice
Loading required package: rgl
Loading required package: gplots

Attaching package: ‘gplots’

The following object is masked from ‘package:stats’:

    lowess

Loading required package: RFclust.SGE
Loading required package: MASS
Loading required package: cluster
Loading required package: survival
Loading required package: randomForest
randomForest 4.6-12
Type rfNews() to see new features/changes/bug fixes.
Loading required package: Hmisc
Loading required package: lattice
Loading required package: Formula
Loading required package: ggplot2

Attaching package: ‘ggplot2’

The following object is masked from ‘package:randomForest’:

    margin


Attaching package: ‘Hmisc’

The following object is masked from ‘package:randomForest’:

    combine

The following objects are masked from ‘package:base’:

    format.pval, round.POSIXt, trunc.POSIXt, units


blablabla <- NGSexpressionSet( 
	"../data/PMID25158935_DataValues.xls",
	"../data/PMID25158935_Sample_Description.xls",
	name="you object name",
 	namecol="filename",
 	namerow= "GeneID"
 )
Error in (function (classes, fdef, mtable)  : 
  unable to find an inherited method for function ‘NGSexpressionSet’ for signature ‘"character"’
In addition: Warning messages:
1: In rgl.init(initValue, onlyNULL) : RGL: unable to open X11 display
2: 'rgl_init' failed, running with rgl.useNULL = TRUE 
print ( blablabla )

Error in print(blablabla) : object 'blablabla' not found
blablabla <- NGSexpressionSet( 
	read.delim("../data/PMID25158935_DataValues.xls"),
	read.delim("../data/PMID25158935_Sample_Description.xls"),
	name="you object name",
 	namecol="filename",
 	namerow= "GeneID"
 )
Error in `[.data.frame`(S, , namecol) : undefined columns selected
data <- read.delim("../data/PMID25158935_DataValues.xls")
samples <- read.delim("../data/PMID25158935_Sample_Description.xls")

colnames(samples)
colnames(data)
print (colnames(samples))
print (colnames(data))

 [1] "Source.Name"               "Comment.ENA_SAMPLE"       
 [3] "Provider"                  "Characteristics.organism" 
 [5] "Characteristics.strain"    "Characteristics.cell.type"
 [7] "Material.Type.1"           "Comment.LIBRARY_LAYOUT"   
 [9] "Comment.LIBRARY_SOURCE"    "Comment.LIBRARY_STRATEGY" 
[11] "Comment.LIBRARY_SELECTION" "Performer"                
[13] "GroupName"                 "Technology.Type"          
[15] "Comment.ENA_EXPERIMENT"    "Scan.Name"                
[17] "Sample"                    "Comment.FASTQ_URI"        
[19] "Factor.Value.cell.type"    "bam.filename"             
[21] "SampleName"               
 [1] "rownames.ret." "ERR420375"     "ERR420376"     "ERR420384"    
 [5] "ERR420380"     "ERR420379"     "ERR420372"     "ERR420377"    
 [9] "ERR420383"     "ERR420373"     "ERR420381"     "ERR420371"    
[13] "ERR420382"     "ERR420374"     "ERR420378"     "ERR420385"    
print (blablabla <- NGSexpressionSet( 
	"../data/PMID25158935_DataValues.xls",
	"../data/PMID25158935_Sample_Description.xls",
	name="you object name",
 	namecol="Sample",
 	namerow= "GeneID"
 ))
Error in (function (classes, fdef, mtable)  : 
  unable to find an inherited method for function ‘NGSexpressionSet’ for signature ‘"character"’
print (blablabla <- NGSexpressionSet( 
	data,
	samples,
	name="you object name",
 	namecol="Sample",
 	namerow= "GeneID"
 ))
Error in if (outpath == "") { : argument is of length zero
print (blablabla <- NGSexpressionSet( 
	"../data/PMID25158935_DataValues.xls",
	"../data/PMID25158935_Sample_Description.xls",
	name="you object name",
 	namecol="Sample",
 	namerow= "GeneID", outpath=''
 ))
Error in (function (classes, fdef, mtable)  : 
  unable to find an inherited method for function ‘NGSexpressionSet’ for signature ‘"character"’
print (blablabla <- NGSexpressionSet( 
	data,
	samples,
	name="you object name",
 	namecol="Sample",
 	namerow= "GeneID", outpath=''
 ))
An object of class NGSexpressionSet 
named  you object name 
with 24062 genes and 15  samples. 
Annotation datasets (24062,1): 'GeneID'   
Sample annotation (15,21): 'Source.Name', 'Comment.ENA_SAMPLE', 'Provider', 'Characteristics.organism', 'Characteristics.strain', 'Characteristics.cell.type', 'Material.Type.1', 'Comment.LIBRARY_LAYOUT', 'Comment.LIBRARY_SOURCE', 'Comment.LIBRARY_STRATEGY', 'Comment.LIBRARY_SELECTION', 'Performer', 'GroupName', 'Technology.Type', 'Comment.ENA_EXPERIMENT', 'Scan.Name', 'Sample', 'Comment.FASTQ_URI', 'Factor.Value.cell.type', 'bam.filename', 'SampleName'   
print (blablabla@data[1:10,1:10])
        ERR420375 ERR420376 ERR420384 ERR420380 ERR420379 ERR420372 ERR420377
Xkr4            0         0         0         8         0         0         2
Rp1             0         0         0         0         0         0         0
Sox17           0         0         0         0         0         0         3
Mrpl15      19968     24629     11910     26656     19962     26974     31956
Lypla1      26469     31099     10846     54067     33589     21090     64446
Tcea1       47513     37063     27752     74187     47000     40703     81829
Rgs20           0        29        12         4         0         0        22
Atp6v1h     26333     26928     17762     39780     27249     21177     41521
Oprk1           0         0         0         0         0         0        12
Npbwr1          0         0         0         0         0         0         5
        ERR420383 ERR420373 ERR420381
Xkr4            0         0         0
Rp1             0         0         0
Sox17           0         0         0
Mrpl15      29746     30814     31353
Lypla1      53342     68584     38740
Tcea1       72262     76248     57080
Rgs20           6         0        14
Atp6v1h     39280     45085     37798
Oprk1           0         0         0
Npbwr1          0         0         0
blablabla@data[1:10,1:10]
