cp docs/ontology/smarcql.ttl smarcql.ttl.BAK
grep '@prefix' docs/ontology/smarcql.ttl > temp.ttl
riot --output=ntriples docs/ontology/smarcql.ttl | sort | uniq >> temp.ttl
riot --output=turtle temp.ttl > docs/ontology/smarcql.ttl
