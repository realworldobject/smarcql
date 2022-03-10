# smarcql
SPARQL + MARC = SMARCQL

The general idea of using SPARQL to index MARC is introduced in
this [Hanging Together](https://hangingtogether.org/how-marc-can-sparql/) blog post.

This repository is dedicated to publishing code to demonstrate the processes
involved.

The SMARCQL Ontology that corresponds to this output can be found [here](https://realworldobject.github.io/smarcql/).

## Setup Instructions

```
# Clone the SMARCQL repository
git clone https://github.com/realworldobject/smarcql.git
cd smarcql

# Download a set of MARC records for testing
wget https://researchworks.oclc.org/researchdata/libsci/cdf.20160701.library_science.marcxml.xml.gz

# Build the project
sbt package

# Delete the old output file
rm -rf out.nt

# Transform a set of line-separated MARC/XML records into SMARCQL N-Triples
spark-submit \
  --master local[*] \
  --jars \
  $COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-core/3.13.1/jena-core-3.13.1.jar,\
  $COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-base/3.13.1/jena-base-3.13.1.jar,\
  $COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-shaded-guava/3.13.1/jena-shaded-guava-3.13.1.jar,\
  $COURSIER_CACHE/https/repo1.maven.org/maven2/org/apache/jena/jena-iri/3.13.1/jena-iri-3.13.1.jar \
  --files src/main/resources/marcslim2rdf.xsl \
  --class smarcql.BulkXSLT target/scala-2.12/smarcql_2.12-0.1.jar \
  cdf.20160701.library_science.marcxml.xml.gz \
  out \
  marcslim2rdf.xsl
  
# Download blazegraph.jar
wget https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_2_1_6_RC/blazegraph.jar

# Bulkload SMARCQL N-Triples
# (~5 hours on MacBook Pro 8-Core Intel Core i9 @ 2.3 GHz)
java -cp blazegraph.jar com.bigdata.rdf.store.DataLoader src/main/resources/fastload.properties out.nt/part-00000.nt.gz

# Start Blazegraph
java -server -Xmx6g -jar blazegraph.jar
```

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