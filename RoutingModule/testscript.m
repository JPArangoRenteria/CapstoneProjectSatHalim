% Clear workspace and command window
clc; clear; close all;

% Define simulation start time (Year, Month, Day, Hour, Minute, Second)
start_y = 2025; start_mon = 1; start_d = 21;
start_h = 0; start_min = 0; start_s = 0;

% Define simulation end time (Year, Month, Day, Hour, Minute, Second)
stop_y = 2025; stop_mon = 1; stop_d = 21;
stop_h = 1; stop_min = 0; stop_s = 0;

% Define time step (simulation stepping interval in seconds)
stepping_u = 60; % Compute satellite positions every 60 seconds

% Define Walker constellation parameters
numSatellites = 36;      % Total number of satellites in the constellation
numPlanes = 6;           % Number of orbital planes
relativeSpacing = 0;     % Relative spacing between satellites
altitude = 550;          % Altitude in km (converted to meters inside function)
inclination = 53;        % Inclination angle in degrees
walker_type = "star";    % Walker constellation type ("delta" or "star")

% Define ground station data file (ensure this file exists in your workspace)
filename = 'ground_station_data.xlsx';  % Example ground station data file

% Define source and target node indices (adjust based on node mappings)
source = 1;  % Example: Ground Station ID or Satellite ID
target = 5;  % Example: Ground Station ID or Satellite ID

% Define shortest path type:
% 0 - Satellite to Satellite
% 1 - Ground Station to Ground Station
% 2 - Ground Station to Satellite
% 3 - Satellite to Ground Station
st_types = 1; % Example: Satellite to Satellite routing

% Define routing step time (interval for shortest path calculations in seconds)
routing_step = 600; % Compute shortest paths every 10 minutes (600 seconds)

% Call the function
[sc, scenario, accumulatedPathsTable, connectionsTable] = network_path_opt(...
    start_y, start_mon, start_d, start_h, start_min, start_s, ...
    stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
    numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
    walker_type, filename, source, target, st_types, routing_step);

% Run the MATLAB Satellite Scenario sumulation
%play(scenario);
disp(scenario.Accesses)
accs = scenario.Accesses;
paths = accumulatedPathsTable.Path;
%updatePathVisualization(scenario,accumulatedPathsTable);
accessobj = struct();
accessobj.obj = scenario.Accesses;
updatePathTime(scenario,accumulatedPathsTable,accessobj.obj)
play(scenario)
%save_satellite_positions_to_file(scenario, 'satellite_positions.csv', 'csv');
% Display accumulated shortest paths table
disp("Accumulated Shortest Path Table:");
disp(accumulatedPathsTable);

% Display network connections table
disp("Network Connections Table:");
disp(connectionsTable);
