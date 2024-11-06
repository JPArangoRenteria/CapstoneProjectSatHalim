% FSPL Function
function [fsplResults,timeSamples] = calculateFSPL(gsORsat,sat,startTime,endTime,sampleTime,txFreq)

    % Calculate the wavelength of the transmission signal
    txLambda = 3e8 / txFreq;

    % Pre-allocate results for FSPL and time
    duration = seconds(endTime - startTime); % Total simulation time (in sec)
    numSamples = floor(duration / sampleTime); % Number of samples taken
    fsplResults = zeros(numSamples, 0);
    timeSamples = datetime.empty(numSamples, 0);

    if isa(gsORsat,'matlabshared.satellitescenario.GroundStation')
        disp('YES');
        % Iterate over each time step to compute FSPL
        for i = 1:numSamples
        
            % Compute the current simulation time
            currentTime = startTime + seconds((i-1) * sampleTime);
        
            % Error check for valid currentTime
            if currentTime > endTime
                currentTime = endTime;
            end
        
            % Get the satellite's position (geographic / ECEF coordinates)
            [satPos, ~] = states(sat, currentTime, 'CoordinateFrame', 'geographic');
            [satECEF, ~] = states(sat, currentTime, 'CoordinateFrame', 'ecef');
            satPosECEF = [satECEF(1) satECEF(2) satECEF(3)]; % Satellite ECEF coordinates
    
            % Get the ground stations position
            gsPos = [gsORsat.Latitude gsORsat.Longitude gsORsat.Altitude];
    
            % Calculate the Elevation angle between ground station and satellite
            maskAngle = 15;                   % Set mask angle to 5 degrees
            [az,el,vis] = lookangles(gsPos,satPosECEF,maskAngle);
    
            % Calculate the distance between the satellite and the ground station
            d = slantRangeCircularOrbit(el,satPos(3),gsPos(3));
    
            % Compute FSPL using the distance and frequency
            pathLoss = fspl(d,txLambda); %FSPL in dB
            fsplResults(i) = pathLoss ;
            timeSamples(i) = currentTime; % Save current time
        end
    else
        disp('NO');
        % Iterate over each time step to compute FSPL
        for i = 1:numSamples
        
            % Compute the current simulation time
            currentTime = startTime + seconds((i-1) * sampleTime);
        
            % Error check for valid currentTime
            if currentTime > endTime
                currentTime = endTime;
            end
        
            % Get the satellite's position (geographic / ECEF coordinates)
            [sat1Pos, ~] = states(sat, currentTime, 'CoordinateFrame', 'geographic');
            [sat1ECEF, ~] = states(sat, currentTime, 'CoordinateFrame', 'ecef');
            sat1PosECEF = [sat1ECEF(1) sat1ECEF(2) sat1ECEF(3)]; % Satellite ECEF coordinates

            [sat2Pos, ~] = states(gsORsat, currentTime, 'CoordinateFrame', 'geographic');
            [sat2ECEF, ~] = states(gsORsat, currentTime, 'CoordinateFrame', 'ecef');
            sat2PosECEF = [sat2ECEF(1) sat2ECEF(2) sat2ECEF(3)]; % Satellite ECEF coordinates

            d1 = norm(sat1Pos - sat2Pos);
    
            % Calculate the Elevation angle between ground station and satellite
            % maskAngle = 15;                   % Set mask angle to 5 degrees
            % [az,el,vis] = lookangles(gsPos,satPosECEF,maskAngle);
    
            % Calculate the distance between the satellite and the ground station
            % d = slantRangeCircularOrbit(el,satPos(3),gsPos(3));
    
            % Compute FSPL using the distance and frequency
            pathLoss = fspl(d1,txLambda); %FSPL in dB
            fsplResults(i) = pathLoss ;
            timeSamples(i) = currentTime; % Save current time
        
        end
    end
end
