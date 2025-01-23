#!/bin/bash

# Default values
scenario_number=""
application_name=""
architecture="monolith"
server_url="http://localhost:8080/ticket-monster"


shutdown() {
    echo "Shutting down the application"
    # ./scripts/shutdown.sh --all --application_dir_path="./applications/${application_name}"
    exit 1
}

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    --scenario=*)
      scenario_number="${1#*=}"
      ;;
    --application_name=*)
      application_name="${1#*=}"
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name>"
      exit 1
      ;;
  esac
  shift
done

# Check if scenario_number is provided
if [ -z "$scenario_number" ]; then
  echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name>"
  exit 1
fi

# Check if application_name is provided
if [ -z "$application_name" ]; then
  echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name>"
  exit 1
fi

echo "Starting containers for the application: $application_name"

# Start the application
./scripts/startup.sh --${architecture} --application_dir_path="./applications/${application_name}"
if [ $? -ne 0 ]; then
  echo "Failed to start the application"
  exit 1
fi

sleep 10

# Run the web crawler
python3 ./selenium/web_crawler.py ./workflows/${application_name}/scenario-${scenario_number}/${architecture}/frontend.yml localhost
if [ $? -ne 0 ]; then
    echo "Failed to run the web crawler"
    shutdown
fi

newman run "./workflows/${application_name}/scenario-${scenario_number}/${architecture}/workload.json" -n "1" --env-var "server_url=${server_url}" --delay-request 200
if [ $? -ne 0 ]; then
    echo "Failed to run newman"
    shutdown
fi

sleep 5

# Dump the coverage data
java -cp "./jacoco/jacococli.jar:./jacoco/args4j.jar" org.jacoco.cli.internal.Main dump --address localhost --port 6300 --destfile jacoco/coverage_${application_name}_scenario_${scenario_number}.exec
if [ $? -ne 0 ]; then
    echo "Failed to dump the coverage data"
    # shutdown
    exit 1
fi

sleep 2

# Generate the coverage report
java -cp "./jacoco/jacococli.jar:./jacoco/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/coverage_${application_name}_scenario_${scenario_number}.exec" --classfiles "./applications/${application_name}/data/build/target/classes" --sourcefiles "./applications/${application_name}/data/build/src/main/java" --html jacoco/coveragereport_${application_name}_scenario_${scenario_number}
if [ $? -ne 0 ]; then
    echo "Failed to generate the coverage report"
    shutdown
fi

open jacoco/coveragereport_${application_name}_scenario_${scenario_number}/index.html

shutdown

#   $PROJECT_DIR/scripts/startup.sh --microservice --application_dir_path="$application_dir_path"