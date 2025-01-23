#!/bin/bash

# Default values
scenario_number=""
application_name=""
architecture="monolith"
server_url="http://localhost:8080/ticket-monster"

# Function to shut down the application
shutdown() {
    echo "Shutting down the application"
    ./scripts/shutdown.sh --all --application_dir_path="./applications/${application_name}"
    exit 1
}

# Function to dump the coverage data
dump_coverage() {
    local scenario=$1
    echo "Dumping the coverage data for scenario: $scenario"
    java -cp "./jacoco/jacococli.jar:./jacoco/args4j.jar" org.jacoco.cli.internal.Main dump --address localhost --port 6300 --destfile jacoco/coverage_${application_name}_scenario_${scenario}.exec
    if [ $? -ne 0 ]; then
        echo "Failed to dump the coverage data"
        shutdown
    fi
}

# Function to run the coverage process for a specific scenario
run_coverage() {
    local scenario=$1

    echo "Starting containers for the application: $application_name, scenario: $scenario"

    # Start the application
    ./scripts/startup.sh --${architecture} --application_dir_path="./applications/${application_name}"
    if [ $? -ne 0 ]; then
        echo "Failed to start the application"
        shutdown
    fi

    sleep 10

    # Run the web crawler
    python3 ./selenium/web_crawler.py ./workflows/${application_name}/scenario-${scenario}/${architecture}/frontend.yml localhost
    if [ $? -ne 0 ]; then
        echo "Failed to run the web crawler"
        shutdown
    fi

    newman run "./workflows/${application_name}/scenario-${scenario}/${architecture}/workload.json" -n "1" --env-var "server_url=${server_url}" --delay-request 200
    if [ $? -ne 0 ]; then
        echo "Failed to run newman"
        shutdown
    fi

    sleep 5

    # Dump the coverage data for the current scenario
    dump_coverage "$scenario"
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

# List of all scenarios
all_scenarios=("1" "2" "3")  # Add all your scenarios here

if [ "$scenario_number" == "all" ]; then
    for scenario in "${all_scenarios[@]}"; do
        run_coverage "$scenario"
    done

    # Merge the coverage data files
    java -cp "./jacoco/jacococli.jar:./jacoco/args4j.jar" org.jacoco.cli.internal.Main merge jacoco/coverage_${application_name}_scenario_*.exec --destfile jacoco/coverage_${application_name}_all_scenarios.exec
    if [ $? -ne 0 ]; then
        echo "Failed to merge the coverage data"
        shutdown
    fi

    # Generate the coverage report from the merged file
    java -cp "./jacoco/jacococli.jar:./jacoco/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/coverage_${application_name}_all_scenarios.exec" --classfiles "./applications/${application_name}/data/build/target/classes" --sourcefiles "./applications/${application_name}/data/build/src/main/java" --html jacoco/coveragereport_${application_name}_all_scenarios
    if [ $? -ne 0 ]; then
        echo "Failed to generate the coverage report"
        shutdown
    fi

    open jacoco/coveragereport_${application_name}_all_scenarios/index.html
else
    run_coverage "$scenario_number"

    # Generate the coverage report for the single scenario
    java -cp "./jacoco/jacococli.jar:./jacoco/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/coverage_${application_name}_scenario_${scenario_number}.exec" --classfiles "./applications/${application_name}/data/build/target/classes" --sourcefiles "./applications/${application_name}/data/build/src/main/java" --html jacoco/coveragereport_${application_name}_scenario_${scenario_number}
    if [ $? -ne 0 ]; then
        echo "Failed to generate the coverage report"
        shutdown
    fi

    open jacoco/coveragereport_${application_name}_scenario_${scenario_number}/index.html
fi

# Shutdown the application after successful completion
shutdown