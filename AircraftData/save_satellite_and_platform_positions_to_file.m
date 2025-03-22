function [satTable,platTable,accesses]=save_satellite_and_platform_positions_to_file(scenario, platforms, satFilename, platFilename, fileType)
    % Extract satellites and platforms from the scenario
    sats = scenario.Satellites;
    numSats = length(sats);
    numPlatforms = length(platforms);
    
    % Get simulation start and stop times
    startTime = scenario.StartTime;
    stopTime = scenario.StopTime;
    timeStep = scenario.SampleTime;

    % Initialize arrays for storing satellite data
    satIDs = [];
    satLongitudes = [];
    satLatitudes = [];
    satAltitudes = [];
    satNumConnections = [];
    satTimes = [];
    
    % Initialize arrays for storing platform data
    platIDs = [];
    platLongitudes = [];
    platLatitudes = [];
    platAltitudes = [];
    platTimes = [];
    
    % Loop through each time step
    for currentTime = startTime:seconds(timeStep):stopTime
        % Process satellite data
        for i = 1:numSats
            sat = sats(i);
            [satPos, ~] = states(sat, currentTime, 'CoordinateFrame', 'geographic');
            
            % Get the number of connections (active accesses)
            numConnections = 0;
            if isprop(sat, 'Accesses') && ~isempty(sat.Accesses)
                activeAccesses = 0;
                for j = 1:length(sat.Accesses)
                    accessObj = sat.Accesses(j);
                    intervals = accessIntervals(accessObj);
                    if ~isempty(intervals)  % Check if the access has valid intervals
                        startTimes = intervals.StartTime;
                        endTimes = intervals.EndTime;
                        
                        % Check if currentTime falls within any active access interval
                        if any(startTimes <= currentTime & endTimes >= currentTime)
                            activeAccesses = activeAccesses + 1;
                        end
                    end
                end
                numConnections = activeAccesses;
            end
            
            % Append satellite data to arrays
            satIDs = [satIDs; string(sat.Name)];
            satLongitudes = [satLongitudes; satPos(1)];
            satLatitudes = [satLatitudes; satPos(2)];
            satAltitudes = [satAltitudes; satPos(3)];
            satNumConnections = [satNumConnections; numConnections];
            satTimes = [satTimes; string(currentTime)];
        end
        
        % Process platform data
        for i = 1:numPlatforms
            platformObj = platforms(i).PlatformObj;
            [platPos, ~] = states(platformObj, currentTime, 'CoordinateFrame', 'geographic');
            
            % Append platform data to arrays
            platIDs = [platIDs; string(platformObj.Name)];
            platLongitudes = [platLongitudes; platPos(1)];
            platLatitudes = [platLatitudes; platPos(2)];
            platAltitudes = [platAltitudes; platPos(3)];
            platTimes = [platTimes; string(currentTime)];
        end
    end
    accesses = scenario.Accesses;
    % Create a table for storing satellite data
    satTable = table(satIDs, satLongitudes, satLatitudes, satAltitudes, satNumConnections, satTimes, ...
                     'VariableNames', {'SatelliteID', 'Longitude', 'Latitude', 'Altitude', 'NumConnections', 'Time'});
    
    % Create a table for storing platform data
    platTable = table(platIDs, platLongitudes, platLatitudes, platAltitudes, platTimes, ...
                      'VariableNames', {'PlatformID', 'Longitude', 'Latitude', 'Altitude', 'Time'});
    
    % Save satellite data file
    if strcmpi(fileType, 'csv')
        writetable(satTable, satFilename);
    elseif strcmpi(fileType, 'xlsx')
        writetable(satTable, satFilename, 'FileType', 'spreadsheet');
    else
        error('Unsupported file type for satellite data. Use "csv" or "xlsx".');
    end
    
    % Save platform data file
    if strcmpi(fileType, 'csv')
        writetable(platTable, platFilename);
    elseif strcmpi(fileType, 'xlsx')
        writetable(platTable, platFilename, 'FileType', 'spreadsheet');
    else
        error('Unsupported file type for platform data. Use "csv" or "xlsx".');
    end

    fprintf('Satellite positions and connections saved to %s\n', satFilename);
    fprintf('Platform positions over time saved to %s\n', platFilename);
end

