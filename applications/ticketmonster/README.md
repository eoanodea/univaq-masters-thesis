# Commands for running JaCoCo

## Dump the coverage data:

`java -cp "jacococli.jar:args4j.jar" org.jacoco.cli.internal.Main dump --address localhost --port 6300 --destfile coverage.exec`

## Generating the report:

`java -cp "jacococli.jar:args4j.jar" org.jacoco.cli.internal.Main report coverage.exec --classfiles ../data/build/target/classes --sourcefiles ../data/build/src/main/java --html coveragereport`
