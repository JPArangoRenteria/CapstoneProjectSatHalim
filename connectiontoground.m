% Import necessary toolbox
satcomms = satelliteScenario;

% Define simulation time parameters (start and stop time)
startTime = datetime(2024,9,13,0,0,0);  % Start time
stopTime = startTime + hours(3);        % Stop time after 3 hours
% Set the sample time for simulation
sampleTime = 60; % in seconds

% Create a satellite scenario
scenario = satelliteScenario(startTime, stopTime, sampleTime);

% Parameters for Walker Star constellation
numSatellites = 10;  % Total number of satellites
numPlanes = 2;       % Number of orbital planes
inclination = 53;    % Inclination of the orbit in degrees
altitude = 700;    % Altitude of satellites in meters
EarthRadius = 6378.14;
radius = (EarthRadius + altitude) * 1000
rs = 1;              % Relative spacing

% Add the constellation to the scenario
satellites = walkerStar(scenario,radius,inclination,numSatellites,numPlanes,rs);
% Define ground station parameters (Lat, Lon, Alt in meters)
gsLat = 10;   % Latitude in degrees
gsLon = 60;   % Longitude in degrees
gsAlt = 0;    % Altitude in meters (set to 0 for sea level)
dsLat = 37.7749; % Latitude (example: San Francisco)
dsLon = -122.4194; % Longitude (example: San Francisco)
dsAlt = 0; % Altitude in meters
% Add a ground station to the scenario
gs = groundStation(scenario, 'Latitude', gsLat, 'Longitude', gsLon, 'Altitude', gsAlt);
ds = groundStation(scenario,'Latitude', dsLat, 'Longitude', dsLon, 'Altitude', dsAlt);
% Connect the ground station to any satellite in view
accessLinks1 = access(gs, satellites);
accessLinks2 = access(ds,satellites);
disp(accessIntervals(accessLinks1))
disp(accessIntervals(accessLinks2))
% Visualize the scenario
figure;
satelliteScenarioViewer(scenario);

% Run the simulation
play(scenario);
