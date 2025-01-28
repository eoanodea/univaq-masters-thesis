#!/bin/bash

# Default values
scenario_number=""
application_name=""
architecture=""
server_url=""

# Function to shut down the application
shutdown() {
    echo "Shutting down the application"
    ./scripts/shutdown.sh --all --application_dir_path="./applications/${application_name}"
    exit 1
}

# Function to dump the coverage data
dump_coverage() {

    local scenario=$1
    local service=$2
    local port=$3
    
    mkdir -p jacoco/$application_name/$architecture

    echo "Dumping the coverage data for scenario: $scenario, service: $service"
    java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main dump --address localhost --port $port --destfile jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_${service}_scenario_${scenario}.exec
    if [ $? -ne 0 ]; then
        echo "Failed to dump the coverage data for service: $service"
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
    if [ "$architecture" == "monolith" ]; then    
        dump_coverage "$scenario" "monolith" 6300
    else
        dump_coverage "$scenario" "backend-v2" 6300
        dump_coverage "$scenario" "orders-service" 6301
    fi
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
    --architecture=*)
      architecture="${1#*=}"
      ;;
    --server_url=*)
      server_url="${1#*=}"
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name> --architecture=<architecture> --server_url=<server_url>"
      exit 1
      ;;
  esac
  shift
done

# Check if scenario_number is provided
if [ -z "$scenario_number" ]; then
    echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name> --architecture=<[monolith|microservice]> --server_url=<server_url>"
    exit 1
fi

# Check if application_name is provided
if [ -z "$application_name" ]; then
  echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name> --architecture=<[monolith|microservice]> --server_url=<server_url>"
  exit 1
fi

# Check if the architecture is provided and is either monolith or microservice
if [ -z "$architecture" ] || { [ "$architecture" != "monolith" ] && [ "$architecture" != "microservice" ]; }; then
  echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name> --architecture=<[monolith|microservice]> --server_url=<server_url>"
  exit 1
fi

# Check if the server_url is provided
if [ -z "$server_url" ]; then
  echo "Usage: $0 --scenario=<scenario_number> --application_name=<application_name> --architecture=<[monolith|microservice]> --server_url=<server_url>"
  exit 1
fi

# List of all scenarios
all_scenarios=("1" "2" "3")  # Add all your scenarios here

# Remove existing .exec files and reports for the specific scenario or all scenarios
if [ "$scenario_number" == "all" ]; then
    rm -f jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_*_all_scenarios.exec
    rm -rf jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_all_scenarios
else
    rm -f jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_*_scenario_${scenario_number}.exec
    rm -rf jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_scenario_${scenario_number}
fi

if [ "$scenario_number" == "all" ]; then
    for scenario in "${all_scenarios[@]}"; do
        run_coverage "$scenario"
    done

    # Merge the coverage data files
    if [ "$architecture" == "monolith" ]; then
        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main merge jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_monolith_scenario_*.exec --destfile jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_all_scenarios.exec
        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_all_scenarios.exec" --classfiles "./applications/${application_name}/monolith/target/classes" --sourcefiles "./applications/${application_name}/monolith/src/main/java" --html jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_all_scenarios
    else
        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main merge \
        jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_backend-v2_scenario_*.exec \
        jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_orders-service_scenario_*.exec \
        --destfile jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_all_scenarios.exec

        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main report \
            "jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_all_scenarios.exec" \
            --classfiles "./applications/${application_name}/backend-v2/target/classes" \
            --classfiles "./applications/${application_name}/orders-service/target/classes" \
            --sourcefiles "./applications/${application_name}/backend-v2/src/main/java" \
            --sourcefiles "./applications/${application_name}/orders-service/src/main/java" \
            --html jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_all_scenarios
    
    fi

    if [ $? -ne 0 ]; then
        echo "Failed to merge and generate the coverage data"
        shutdown
    fi

    # # Generate the coverage report from the merged file
    # java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_all_scenarios.exec" --classfiles "./applications/${application_name}/monolith/target/classes" --sourcefiles "./applications/${application_name}/monolith/src/main/java" --html jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_all_scenarios
    # if [ $? -ne 0 ]; then
    #     echo "Failed to generate the coverage report"
    #     shutdown
    # fi

    open jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_all_scenarios/index.html
else
    run_coverage "$scenario_number"

    # Generate the coverage report for the single scenario
    if [ "$architecture" == "monolith" ]; then
        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_monolith_scenario_${scenario_number}.exec" --classfiles "./applications/${application_name}/monolith/target/classes" --sourcefiles "./applications/${application_name}/monolith/src/main/java" --html jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_scenario_${scenario_number}
    else
        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main merge \
         jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_backend-v2_scenario_${scenario_number}.exec \
         jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_orders-service_scenario_${scenario_number}.exec \
         --destfile jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_scenario_${scenario_number}.exec
        
        # java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main report "jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_scenario_${scenario_number}.exec" --classfiles "./applications/${application_name}/backend-v2/target/classes" --sourcefiles "./applications/${application_name}/backend-v2/src/main/java" --html jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_scenario_${scenario_number}

        java -cp "./jacoco/lib/jacococli.jar:./jacoco/lib/args4j.jar" org.jacoco.cli.internal.Main report \
          "jacoco/$application_name/$architecture/coverage_${application_name}_${architecture}_scenario_${scenario_number}.exec" \
          --classfiles "./applications/${application_name}/backend-v2/target/classes" \
          --classfiles "./applications/${application_name}/orders-service/target/classes" \
          --sourcefiles "./applications/${application_name}/backend-v2/src/main/java" \
          --sourcefiles "./applications/${application_name}/orders-service/src/main/java" \
          --html "jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_scenario_${scenario_number}"
    fi
    
    if [ $? -ne 0 ]; then
        echo "Failed to generate the coverage report"
        shutdown
    fi

    open jacoco/$application_name/$architecture/coveragereport_${application_name}_${architecture}_scenario_${scenario_number}/index.html
fi

# Shutdown the application after successful completion
shutdown