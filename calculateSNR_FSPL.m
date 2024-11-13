% Create CNR Config object to for satelliteCNR function
cfg = satelliteCNRConfig;
cfg.TransmitterPower = 15;                          % in dBW
cfg.TransmitterSystemLoss = 9;                      % in dB
cfg.TransmitterAntennaGain = 38;                    %in dBi
cfg.Frequency = 2.4;                                % in GHz
cfg.MiscellaneousLoss = 6;                          % in dB
cfg.GainToNoiseTemperatureRatio = cfg.TransmitterPower * cfg.TransmitterAntennaGain / 290;    % in dB/K
cfg.ReceiverSystemLoss = 2;                         % in dB
cfg.BitRate = 10;                                   % in Mbps

% SNR and FSPL Function
function [snrResults,fsplResults,timeSamples] = calculateSNR_FSPL(gsORsat,sat,cfg,startTime,duration,sampleTime)

    % Pre-allocate results for FSPL and time
    endTime = startTime + seconds(duration); % Total simulation time (in sec)
    numSamples = floor(duration / sampleTime); % Number of samples taken
    snrResults = zeros(numSamples, 0);
    fsplResults = zeros(numSamples, 0);
    timeSamples = datetime.empty(numSamples, 0);
    timeSamples.TimeZone = 'UTC';

    % Check gsORsat Object type
    if isa(gsORsat,'matlabshared.satellitescenario.GroundStation')
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
            d = slantRangeCircularOrbit(el,satPos(3),gsPos(3)); % in meters
            cfg.Distance = d/1000;
    
            % Compute FSPL using the distance and frequency
            % pathLoss = fspl(d,wl); %FSPL in dB
            [cn,info] = satelliteCNR(cfg);
            snrResults(i) = cn;
            fsplResults(i) = info.FSPL ;
            timeSamples(i) = currentTime; % Save current time
        end
    else
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
            [sat2Pos, ~] = states(gsORsat, currentTime, 'CoordinateFrame', 'geographic');

            % Calculate the distance between the two satellites
            d = norm(sat1Pos - sat2Pos);
            cfg.Distance = d/1000;
    
            % Compute SNR and FSPL using the satelliteCNRConfig object
            [cn,info] = satelliteCNR(cfg);
            snrResults(i) = cn;             % Save SNR result
            fsplResults(i) = info.FSPL ;    % Save FSPL result
            timeSamples(i) = currentTime;   % Save current time
        
        end
    end
end
