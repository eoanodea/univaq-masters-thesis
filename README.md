# 📈 Monolith vs. Microservices Power Consumption Comparison

This project contains an experiment built to measure the energy consumption of various architectures of an application. Multiple applications have been tested including [TicketMonster](https://github.com/ticket-monster-msa/monolith) and [PetClinic](https://github.com/spring-petclinic). The experiment expects two versions of the application (Monolith and Microservices architecutres), where a variety of workloads are executed on the application to measure the energy consumption.

## 🏗️ Project structure

The project is broken up into two parts: the monolith and the microservices. The monolith is located in the `monolith` folder, and the microservices are broken up between three folders:

- `applications` The applications used in the experiment (Are not included, need to be cloned seperately)
- `data-extaction` The scripts used to extract data after an experiemnt, preparing for data analysis
- `data-visualisation` A collection of visualised experiments, containing graphs and analysis
- `output` Where data will be stored after an experiment (May need to be created)
- `scripts` A collection of bash scripts used to run the experiment
- `selenium` The selenium scripts used to navigate the frontend of the application (One phase of the experiment)
- `workflows` The workflows used in the experiment, containing the Selenium and Newman configurations, where you give your instructions on what workloads to perform on an experiment

## 🥅 Goal

The goal of this project is to compare the energy consumption of the monolith and microservice architectures, using a collection of bash scripts that utilise [Selenium](https://www.selenium.dev/), [Docker](https://www.docker.com/), [Newman CLI](https://github.com/postmanlabs/newman) and [Powerstat](https://github.com/ColinIanKing/powerstat).

![Refined Methodology](./refined-methodology.png)

> The architecture of the experiment

## 💻 Software Prerequisites

To run this project you will need the following installed on your system:

- [Docker](https://www.docker.com/)
- [Python3](https://www.python.org/downloads/)
- jq (`sudo apt-get install jq -y`)
- [newman](https://github.com/postmanlabs/newman)
- [Powerstat](https://github.com/ColinIanKing/powerstat)
- pyyaml - `pip3 install pyyaml`

## 🏗️ Hardware Prerequisites

The experiment is designed to be run on a Linux machine, and requires the following hardware:

- A Ubuntu Server 20.04 LTS machine
- A second laptop or desktop machine
- A stable local WiFi Network

## ✅ Getting started

To run this project you will need to complete the following steps:

1. Clone this repository to your server machine
2. Clone the monolith and microservices applications to your server machine
3. Ensure all prerequisites are installed (See previous section)
4. Prepare your scripts (e.g. check `workflows/ticketmonster/scenario-1/`), there are two directories: monolith and microservice, each requiring the following files:
   - `frontend.yml` - Contains a list of instructions for Selenium to follow to navigate and execute tasks on the frontend, you can test this by directly executing these files with the `selenium/web_crawler.py` script
   ```
   python3 web_crawler.py monolith-config.yaml localhost
   ```
   - `workload.json` - Contains a list of instructions for Newman to follow to execute tasks on the backend (This can be generated using the Postman GUI, and exported to a JSON file)
   - `experiment.yml` - only created once outside of these directories, and contains a list of instructions for the experiment to follow, including the paths to the `frontend.yml` and `workload.json` files.
     At the end, you will have a directory structure like this:
   ```
   .
   ├── experiment.yml
   ├── microservice
   │   ├── frontend.yml
   │   └── workload.json
   └── monolith
       ├── frontend.yml
       └── workload.json
   ```
5. Run `cp example.env .env` and fill in the following values:

   - `SSH_USER` - The username of the user on the remote machine
   - `SSH_HOST` - The IP address of the remote machine
   - `SSH_KEY_PATH` - The path to the SSH key used to connect to the remote machine
   - `PROJECT_DIR` - The path to the project directory on the server machine (Run `pwd` to get this)
   - You need to set up the client machine to accept SSH connections.

6. Run `./init.sh` to initiate the experiment. It will check that all dependencies are installed, and ask you to confirm the configuration before starting.

### 💻 Available Scripts

- `./init.sh` Initialises the experiment, checking that all dependencies are installed and asking you to confirm the configuration before starting
- `./scripts/prereq.sh` Checks that all dependencies are installed and that the experiment is correctly configured
- `./scripts/startup.sh [--monolith | --microservice | --all] --application_dir_path=./path_to_application` Starts the monolith or microservices containers based on the docker compose files
- `./scripts/shutdown.sh [--monolith | --microservice | --all] --application_dir_path=./path_to_application` Shuts down any running services
- `./scripts/monitor.sh --architecture --iterations --workload_iterations --sleep_time --output --sampling_frequency --frontend_workflow --backend_workflow` Monitors the specified service for the specified number of iterations, and a specified duration (in seconds). The results are saved in the `output` folder

### Selenium Commands

Selenium can be tested separate of the entire experiment by navigating to the `selenium` directory and running the following command:

`python3 web_crawler.py monolith-config.yaml localhost`

Where the final argument is the IP address of the server machine.

> Make sure you have the dependencies installed first `pip install -r dependencies.txt`

### Coverage Reports

To run the coverage script

For Ticket Monster Monolith

```
./scripts/coverage.sh --scenario=all --application_name=ticketmonster --architecture=monolith --server_url="http://localhost:8080/ticket-monster"
```

For Ticket Monster MS

```
./scripts/coverage.sh --scenario=all --application_name=ticketmonster --architecture=microservice --server_url="http://localhost:5000"
```

Run all three quick in one go

```
./scripts/coverage.sh --scenario=1 --application_name=ticketmonster --architecture=microservice --server_url="http://localhost:5000" && ./scripts/coverage.sh --scenario=2 --application_name=ticketmonster --architecture=microservice --server_url="http://localhost:5000" && ./scripts/coverage.sh --scenario=3 --application_name=ticketmonster --architecture=microservice --server_url="http://localhost:5000"
```

# UML Sequence Diagrams For each scenario

## Scenario 1

```mermaid
sequenceDiagram
    title Scenario 1 - Light User Load Monolith

    User->Monolithic Application: Browse Tickets
    Monolithic Application->Database: Fetch Data
    Database-->Monolithic Application: Data
    Monolithic Application-->User: Data
```

```mermaid
sequenceDiagram
    title Scenario 1 - Light User Load Microservice
    User->Frontend: Browse Tickets
    Frontend->Orders Service: Request Tickets
    Orders Service->Backend: Get Ticket Data
    Backend->Database: Fetch Data
    Database-->Backend: Data
    Backend-->Orders Service: Data
    Orders Service-->Frontend: Data
    Frontend-->User: Data
```

## Scenario 2

```mermaid
sequenceDiagram
    title Scenario 2 - Heavy User Load Monolith

    User->Monolithic Application: Purchase Tickets
    Monolithic Application->Database: Process Purchase
    Database-->Monolithic Application: Data
    User->Monolithic Application: Update Information
    Monolithic Application->Database: Update Information
    Database-->Monolithic Application: Updated Information
    Monolithic Application-->User: Response
```

```mermaid
sequenceDiagram
    title Scenario 2 - Heavy User Load Microservice

    User->Frontend: Purchase Tickets
    Frontend->Orders Service: Create Order
    Orders Service->Backend: Process Purchase
    Backend->Database: Update Order
    Database-->Backend: Order Data
    Backend-->Orders Service: Order Data
    Orders Service-->Frontend: Order Confirmation
    Frontend->Frontend: Update Information
    Frontend->Orders Service: Update User Information
    Orders Service->Backend: Update User Info
    Backend->Database: Update User Record
    Database-->Backend: User Data
    Backend-->Orders Service: User Data
    Orders Service-->Frontend: Updated User Info
    Frontend-->User: Response
```

## Scenario 3

```mermaid
sequenceDiagram
    title Scenario 3 - Heavy Admin Load Monolith
    Admin->Monolithic Application: Create Info
    Monolithic Application->Database: Create Record
    Database-->Monolithic Application: Record Created
    Admin->Monolithic Application: Read Info
    Monolithic Application->Database: Read Record
    Database-->Monolithic Application: Record Data
    Admin->Monolithic Application: Update Info
    Monolithic Application->Database: Update Record
    Database-->Monolithic Application: Record Updated
    Admin->Monolithic Application: Delete Info
    Monolithic Application->Database: Delete Record
    Database-->Monolithic Application: Record Deleted
```

```mermaid
sequenceDiagram
    title Scenario 3 - Heavy Admin Load Microservice
    Admin->Frontend: Create Info
    Frontend->Orders Service: Create Record
    Orders Service->Backend: Create Record
    Backend->Database: Store Record
    Database-->Backend: Record Created
    Backend-->Orders Service: Record Created
    Orders Service-->Frontend: Record Created
    Admin->Frontend: Read Info
    Frontend->Orders Service: Read Record
    Orders Service->Backend: Retrieve Record
    Backend->Database: Fetch Data
    Database-->Backend: Record Data
    Backend-->Orders Service: Record Data
    Orders Service-->Frontend: Record Data
    Admin->Frontend: Update Info
    Frontend->Orders Service: Update Record
    Orders Service->Backend: Update Record
    Backend->Database: Modify Record
    Database-->Backend: Record Updated
    Backend-->Orders Service: Record Updated
    Orders Service-->Frontend: Record Updated
    Admin->Frontend: Delete Info
    Frontend->Orders Service: Delete Record
    Orders Service->Backend: Delete Record
    Backend->Database: Remove Record
    Database-->Backend: Record Deleted
    Backend-->Orders Service: Record Deleted
    Orders Service-->Frontend: Record Deleted
```

## Detailed Sequence Diagram - Scenario 1

```mermaid
sequenceDiagram
    title Scenario 1 - Light User Load Monolith

    participant U as User
    participant Api as API
    participant App as Monolithic Application
    participant DB as Database
    %% participant Sel as Selenium

    U->>App: Browse Tickets
    App->>DB: Fetch Data
    DB-->>App: Data
    App-->>U: Data

    U->>App: Navigate to 'Events'
    App->>DB: Retrieve 'Events' data
    DB-->>App: 'Events' data
    App-->>U: Display 'Events' page

    U->>App: Navigate to 'Concert'
    App->>DB: Retrieve 'Concert' data
    DB-->>App: 'Concert' data
    App-->>U: Display 'Concert' page

    U->>App: Navigate to 'Rock concert of the decade'
    App->>DB: Retrieve 'Rock concert of the decade' data
    DB-->>App: 'Rock concert of the decade' data
    App-->>U: Display 'Rock concert of the decade' page

    U->>App: Provide order details (e.g., email, dropdown, quantity)
    App->>DB: Save order details
    DB-->>App: Confirmation of order details
    App-->>U: Order details processed

    U->>App: Click 'Add tickets'
    App->>DB: Add tickets to the order
    DB-->>App: Ticket added
    App-->>U: Tickets added to the order

    U->>App: Click 'Checkout'
    App->>DB: Process checkout
    DB-->>App: Checkout completed
    App-->>U: Checkout success

    % API Testing Part

    U->>Api: Get Events
    Api->>DB: Retrieve Events
    DB-->>Api: Events data
    Api-->>U: Events retrieved

    U->>Api: Get Event by ID
    Api->>DB: Retrieve Event by ID
    DB-->>Api: Event data
    Api-->>U: Event by ID retrieved

    U->>Api: Get Venues
    Api->>DB: Retrieve Venues
    DB-->>Api: Venues data
    Api-->>U: Venues retrieved

    U->>Api: Get Categories
    Api->>DB: Retrieve Categories
    DB-->>Api: Categories data
    Api-->>U: Categories retrieved

    U->>Api: Get Sections
    Api->>DB: Retrieve Sections
    DB-->>Api: Sections data
    Api-->>U: Sections retrieved

    U->>Api: Get Performances
    Api->>DB: Retrieve Performances
    DB-->>Api: Performances data
    Api-->>U: Performances retrieved
```

```mermaid
sequenceDiagram
    title Scenario 1 - Microservices Architecture

    participant U as User
    participant Frontend as Frontend Service
    participant Backend as Backend Service
    participant Database as Database
    participant Orders as Orders Service
    participant API as API Service

    U->>Frontend: Browse Tickets
    Frontend->>Backend: Request Ticket Information
    Backend->>Database: Fetch Data
    Database-->>Backend: Data
    Backend-->>Frontend: Ticket Information
    Frontend-->>U: Display Ticket Information


    U->>Frontend: Navigate to 'Events'
    Frontend->>Backend: Request Events Data
    Backend->>Database: Fetch Events Data
    Database-->>Backend: Events Data
    Backend-->>Frontend: Events Data
    Frontend-->>U: Display 'Events' page

    U->>Frontend: Navigate to 'Concert'
    Frontend->>Backend: Request Concert Data
    Backend->>Database: Fetch Concert Data
    Database-->>Backend: Concert Data
    Backend-->>Frontend: Concert Data
    Frontend-->>U: Display 'Concert' page

    U->>Frontend: Navigate to 'Rock concert of the decade'
    Frontend->>Backend: Request Rock Concert Data
    Backend->>Database: Fetch Rock Concert Data
    Database-->>Backend: Rock Concert Data
    Backend-->>Frontend: Rock Concert Data
    Frontend-->>U: Display 'Rock concert of the decade' page

    U->>Frontend: Provide order details (e.g., email, dropdown, quantity)
    Frontend->>Backend: Submit Order Details
    Backend->>Orders: Create Order
    Orders->>Database: Save Order Details
    Database-->>Orders: Order Details
    Orders-->>Backend: Order Created
    Backend-->>Frontend: Order Confirmation
    Frontend-->>U: Order Confirmation

    U->>Frontend: Click 'Add tickets'
    Frontend->>Backend: Request Add Tickets
    Backend->>Orders: Add Tickets to Order
    Orders->>Database: Update Order
    Database-->>Orders: Updated Order
    Orders-->>Backend: Tickets Added
    Backend-->>Frontend: Tickets Added
    Frontend-->>U: Tickets Added

    U->>Frontend: Click 'Checkout'
    Frontend->>Backend: Request Checkout
    Backend->>Orders: Process Checkout
    Orders->>Database: Update Order Status
    Database-->>Orders: Updated Order Status
    Orders-->>Backend: Checkout Completed
    Backend-->>Frontend: Checkout Success
    Frontend-->>U: Checkout Success

    % API Testing Part

    U->>API: Get Events
    API->>Backend: Request Events
    Backend->>Database: Fetch Events Data
    Database-->>Backend: Events Data
    Backend-->>API: Events Data
    API-->>U: Events Retrieved

    U->>API: Get Event by ID
    API->>Backend: Request Event by ID
    Backend->>Database: Fetch Event Data by ID
    Database-->>Backend: Event Data
    Backend-->>API: Event Data
    API-->>U: Event by ID Retrieved

    U->>API: Get Venues
    API->>Backend: Request Venues
    Backend->>Database: Fetch Venues Data
    Database-->>Backend: Venues Data
    Backend-->>API: Venues Data
    API-->>U: Venues Retrieved

    U->>API: Get Categories
    API->>Backend: Request Categories
    Backend->>Database: Fetch Categories Data
    Database-->>Backend: Categories Data
    Backend-->>API: Categories Data
    API-->>U: Categories Retrieved

    U->>API: Get Sections
    API->>Backend: Request Sections
    Backend->>Database: Fetch Sections Data
    Database-->>Backend: Sections Data
    Backend-->>API: Sections Data
    API-->>U: Sections Retrieved

    U->>API: Get Performances
    API->>Backend: Request Performances
    Backend->>Database: Fetch Performances Data
    Database-->>Backend: Performances Data
    Backend-->>API: Performances Data
    API-->>U: Performances Retrieved

```

## Some more sequence diagrams

```mermaid
sequenceDiagram
  participant User
  participant Monolith
  participant Database

  User->>Monolith: Purchase Ticket
  Monolith->>Database: Process Purchase
  Database-->>Monolith: Purchase Confirmation
  Monolith-->>User: Display Purchase Confirmation
```

```mermaid
sequenceDiagram
  participant User
  participant Frontend
  participant Backend
  participant OrdersService
  participant Database

  User->>Frontend: Purchase Ticket
  Frontend->>Backend: Send Ticket Purchase Request
  Backend->>OrdersService: Process Order
  OrdersService->>Database: Save Order Information
  Database-->>OrdersService: Order Confirmation
  OrdersService-->>Backend: Purchase Confirmation
  Backend-->>Frontend: Purchase Confirmation
  Frontend-->>User: Display Purchase Confirmation
```
