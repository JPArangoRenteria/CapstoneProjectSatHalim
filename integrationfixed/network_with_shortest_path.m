function [sc, scenario, accumulatedTable,connectionsTable] = network_with_shortest_path( ...
    start_y, start_mon, start_d, start_h, start_min, start_s, ...
    stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
    numSatellites, numPlanes, relativeSpacing, altitude, inclination, ...
    walker_type, filename, source, target,routing_step)

    % Create the scenario and constellation
    [sc, scenario] = walker_constellation(start_y, start_mon, start_d, start_h, start_min, start_s, ...
        stop_y, stop_mon, stop_d, stop_h, stop_min, stop_s, stepping_u, ...
        numSatellites, numPlanes, relativeSpacing, altitude, inclination, walker_type);
    
    sats = scenario.Satellites; % Satellites in the scenario
    GS = groundstations(filename, scenario); % Ground stations from the input file

    % Create mappings for nodes
    nodeMapping = createNodeMapping(sats, GS);
    reverseMapping = createReverseMapping(sats, GS);

    % Define time parameters
    totalTime = scenario.StopTime - scenario.StartTime;
    timeStep = routing_step; % Seconds per step
    numTimeSteps = floor(seconds(totalTime) / timeStep);

    % Initialize results
    accumulatedPaths = cell(numTimeSteps, 1);
    accumulatedDistances = NaN(numTimeSteps,1);%zeros(numTimeSteps, 1);
    timeIntervals = NaT(numTimeSteps,1);%datetime.empty(numTimeSteps, 0);

    % Loop through time steps
    for t = 1:numTimeSteps
        currentTime = scenario.StartTime + seconds(t * timeStep);
        currentTime.TimeZone = ''; % Ensure no time zone mismatch
        % Create the connections table for the current time
        connectionsTable = createConnectionsTable(sats, numSatellites, numPlanes, currentTime);

        % Build a graph from the connections table
        G = graph(connectionsTable.Source, connectionsTable.Target, connectionsTable.Weight);

        % Compute the shortest path using MATLAB's shortestpath function
        [path,dist] = shortestpath(G, nodeMapping.Satellites(source), nodeMapping.Satellites(target));
        disp(dist)
        disp(path)
        % Store results
        accumulatedPaths{t} = path;
        accumulatedDistances(t) = dist;
        disp(currentTime)
        timeIntervals(t) = currentTime;
    end

    % Create a table with the results
    accumulatedTable = table(timeIntervals, accumulatedPaths, accumulatedDistances, ...
        'VariableNames', {'TimeInterval', 'Path', 'Weight'});

end

% Function to map nodes to indices
function nodeMapping = createNodeMapping(constellation, groundStations)
    nodeMapping = struct('GroundStations', [], 'Satellites', []);
    for i = 1:numel(groundStations)
        nodeMapping.GroundStations(i) = i;
    end
    for i = 1:numel(constellation)
        nodeMapping.Satellites(i) = numel(groundStations) + i;
    end
end

% Function to map indices back to nodes
function reverseMapping = createReverseMapping(constellation, groundStations)
    reverseMapping = struct();
    for i = 1:numel(groundStations)
        reverseMapping(i).Type = 'GroundStation';
        reverseMapping(i).Object = groundStations(i);
    end
    for i = 1:numel(constellation)
        idx = numel(groundStations) + i;
        reverseMapping(idx).Type = 'Satellite';
        reverseMapping(idx).Object = constellation(i);
    end
end

% Function to create the connections table
function connectionsTable = createConnectionsTable(sats, numSatellites, numPlanes, time)
    c = 3e8; % Speed of light (m/s)
    numSatellitesPerPlane = numSatellites / numPlanes;

    connectionsCell = {}; % Store connections as cell array

    for plane = 1:numPlanes
        for sat = 1:numSatellitesPerPlane
            currentIndex = (plane - 1) * numSatellitesPerPlane + sat;

            % Right neighbor
            if sat < numSatellitesPerPlane
                rightNeighborIndex = currentIndex + 1;
                delay = calculateDelay(sats(currentIndex), sats(rightNeighborIndex), time, c);
                if delay > 0
                    connectionsCell = [connectionsCell; {currentIndex, rightNeighborIndex, delay}];
                end
            end

            % Left neighbor
            if sat > 1
                leftNeighborIndex = currentIndex - 1;
                delay = calculateDelay(sats(currentIndex), sats(leftNeighborIndex), time, c);
                if delay > 0
                    connectionsCell = [connectionsCell; {currentIndex, leftNeighborIndex, delay}];
                end
            end

            % Up neighbor
            if plane < numPlanes
                upNeighborIndex = currentIndex + numSatellitesPerPlane;
                if upNeighborIndex <= numSatellites
                    delay = calculateDelay(sats(currentIndex), sats(upNeighborIndex), time, c);
                    if delay > 0
                        connectionsCell = [connectionsCell; {currentIndex, upNeighborIndex, delay}];
                    end
                end
            end

            % Down neighbor
            if plane > 1
                downNeighborIndex = currentIndex - numSatellitesPerPlane;
                if downNeighborIndex > 0
                    delay = calculateDelay(sats(currentIndex), sats(downNeighborIndex), time, c);
                    if delay > 0
                        connectionsCell = [connectionsCell; {currentIndex, downNeighborIndex, delay}];
                    end
                end
            end
        end
    end

    % Convert to table
    connectionsTable = cell2table(connectionsCell, 'VariableNames', {'Source', 'Target', 'Weight'});
end

% Function to calculate delay
function delay = calculateDelay(obj1, obj2, time, c)
    distance = calculateDistance(obj1, obj2, time);
    delay = distance / c; % Delay in seconds
end

% Function to calculate distance
function distance = calculateDistance(obj1, obj2, time)
    if isa(obj1, 'matlabshared.satellitescenario.Satellite')
        [pos1, ~] = states(obj1, time, "CoordinateFrame", "geographic");
    elseif isa(obj1, 'matlabshared.satellitescenario.GroundStation')
        pos1 = [obj1.Latitude, obj1.Longitude, obj1.Altitude];
    else
        error('Unsupported object type for obj1.');
    end

    if isa(obj2, 'matlabshared.satellitescenario.Satellite')
        [pos2, ~] = states(obj2, time, "CoordinateFrame", "geographic");
    elseif isa(obj2, 'matlabshared.satellitescenario.GroundStation')
        pos2 = [obj2.Latitude, obj2.Longitude, obj2.Altitude];
    else
        error('Unsupported object type for obj2.');
    end

    % Euclidean distance
    distance = norm(pos1 - pos2);
end
