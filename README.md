# smarcql
SPARQL + MARC = SMARCQL

The general idea of using SPARQL to index MARC is introduced in
this [Hanging Together](https://hangingtogether.org/how-marc-can-sparql/) blog post.

This repository is dedicated to publishing code to demonstrate the processes
involved.

The SMARCQL Ontology that corresponds to this output can be found [here](https://realworldobject.github.io/smarcql/).

## Setup Instructions
These setup instructions aren't ideal, but for an alpha realease they might be good enough. Feel free
to [create new issues](https://github.com/realworldobject/smarcql/issues) in the Github repository if you have 
suggestions to improve the process.
### Clone the repository, build the project, and initialize Blazegraph with the SMARCQL Ontology.
```
# Clone the SMARCQL repository
git clone https://github.com/realworldobject/smarcql.git
cd smarcql

# Build the project
sbt package

# Download blazegraph.jar
wget https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_2_1_6_RC/blazegraph.jar

# Delete the existing Blazegraph journal file, if present
rm -rf blazegraph.jnl

# Load the ontology
java -cp blazegraph.jar com.bigdata.rdf.store.DataLoader src/main/resources/fastload.properties docs/ontology/smarcql.ttl
```

### Choose a MARC dataset to transform and load

#### Example 1: OCLC Research "Library Science" subset of WorldCat

The unzipped format of this download is one XML record per line, so the spark-submit step reads the file line-by-line 
to perform the MARC to SMARCQL transformation.

```
# Download a set of MARC records for testing
wget https://researchworks.oclc.org/researchdata/libsci/cdf.20160701.library_science.marcxml.xml.gz

# Delete the old output file
rm -rf out.nt

# Transform a set of line-separated MARC/XML records into SMARCQL N-Triples
# (~1 hour on MacBook Pro 8-Core Intel Core i9 @ 2.3 GHz)
spark-submit\
 --master local[*]\
 --jars\
 $COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-core/3.13.1/jena-core-3.13.1.jar,\
$COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-base/3.13.1/jena-base-3.13.1.jar,\
$COURSIER_CACHE/https/repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.6/Saxon-HE-10.6.jar,\
$COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-shaded-guava/3.13.1/jena-shaded-guava-3.13.1.jar,\
$COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-iri/3.13.1/jena-iri-3.13.1.jar\
 --files src/main/resources/marcslim2rdf.xsl,src/main/resources/log4j.properties\
 --class com.github.smarcql.BulkXSLT target/scala-2.12/smarcql_2.12-0.1.jar\
 cdf.20160701.library_science.marcxml.xml.gz\
 out\
 marcslim2rdf.xsl
 
# Hack the Spark "parts" output filename so the loader recognizes it as GZipped N-Triples (.nt.gz)
mv out.nt/part-00000.gz out.nt/part-00000.nt.gz

# Index the N-triples in Blazegraph

# If you're on a Mac, run this command in a 2nd windows so it doesn't go to sleep.
caffeinate

# Bulkload SMARCQL N-Triples
# (~5 hours on MacBook Pro 8-Core Intel Core i9 @ 2.3 GHz)
java -cp blazegraph.jar com.bigdata.rdf.store.DataLoader src/main/resources/fastload.properties out.nt/part-00000.nt.gz

# Start Blazegraph
java -server -Xmx6g -jar blazegraph.jar
```

#### Option 2: Library of Congress "[Serials: MDSConnect](https://www.loc.gov/item/2020445558)" dataset

The unzipped format of this download is a folder containing a set of Gzipped XML "part" files. In this situation, it
was easier to perform the XSL transformation by looping through the files using Saxon's command-line interface.

Also in this case, the MARC data wasn't in Unicode Normal Form C (NFC), which is the standard for RDF, so a call is 
made to [com.github.smarcql.NormalizerNFC](https://github.com/realworldobject/smarcql/blob/main/src/main/scala/com/github/smarcql/NormalizerNFC.scala).

```
# Download a set of MARC records for testing
wget https://tile.loc.gov/storage-services/master/gdc/gdcdatasets/2020445558_2019/2020445558_2019.zip

unzip 2020445558_2019.zip

# Process LC MARC parts files, convert to NFC, transform to SMARCQL RDF and Gzip the parts
for f in 2020445558_2019/Serials.2019.part*.xml.gz;
  do
    echo $f
    gzcat $f | java -cp ~/.sbt/boot/scala-2.12.15/lib/scala-library.jar:target/scala-2.12/smarcql_2.12-0.1.jar com.github.smarcql.NormalizerNFC |  java -Xmx6g -jar /Users/jyoung/Library/Caches/Coursier/v1/https/repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.6/Saxon-HE-10.6.jar -s:- -xsl:src/main/resources/marcslim2rdf.xsl baseURI=https://lccn.loc.gov/ | rdfxml --output=ntriples | gzip > $f.nt.gz
  done

# Index the N-triples in Blazegraph

# If you're on a Mac, run this command in a 2nd windows so it doesn't go to sleep.
caffeinate

# Bulkload SMARCQL N-Triples
java -cp blazegraph.jar com.bigdata.rdf.store.DataLoader src/main/resources/fastload.properties 2020445558_2019/Serials.2019.part*.xml.gz.nt.gz

# Start Blazegraph
java -server -Xmx6g -jar blazegraph.jar
```

### Testing
Once Blazegraph has started, the default workbench location is http://localhost:9999/blazegraph/.

Here is a "Hello World!" query to get started, with more to come...
```
PREFIX tag: <https://w3id.org/smarcql/tag/>
PREFIX code: <https://w3id.org/smarcql/code/>

SELECT ?author (GROUP_CONCAT(?title;SEPARATOR="\n") AS ?titles)
WHERE {
  ?rec tag:bd100 [
    code:sa ?author
  ];
  tag:bd245 [
      code:sa ?title
  ]
}
GROUP BY ?author
ORDER BY DESC(COUNT(?title))
LIMIT 100
```