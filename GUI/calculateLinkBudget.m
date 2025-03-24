% 1. Inputs
% - Carrier Frequency (GHz)		- Straight to cfg variable
% - Bandwidth (MHz)			- Straight to cfg variable
% - Transmitter Power (dBW)		- Straight to cfg variable
% - Transmitter System Loss (dB)		- Straight to cfg variable
% - Transmitter Gain (dBi)		- Straight to cfg variable
% - Miscellaneous Loss (dB) ????		- Straight to cfg variable
% - Receiver Gain (dBi)			- Used to calculate Gain 2 Noise Ratio
% - Receiver System Loss (dB)		- Straight to cfg variable
% - Modulation Scheme (QAM, PSK, FSK)
% - Modulation Order (2,4,8,16,32)
% - Modulation Index

% 2. Calculate Gain 2 Noise Ratio
% - cfg.GainToNoiseTemperatureRatio = ReceiverGain - 10*log10(290)

% 3. Calculate Bit Rate
% - cfg.BitRate = calculateBitRate

% 4. Calculate Link Budget

% # Calculates link budget only during link intervals
% [latResults,berResults,snrResults,fsplResults,distance,timeSamples] = calculateLinkBudget_multipleIntervals(gsORsat,sat,cfg,modType,modOrder,modIndex,sampleTime)

% OR

% # Calculates link budget for whole duration from start time
% [latResults,berResults,snrResults,fsplResults,distance,timeSamples] = calculateLinkBudget(gsORsat,sat,cfg,modType,modOrder,modIndex,startTime,duration,sampleTime)





% Link Budget Function (Latency, BER, SNR, FSPL, Distance, Time)
function [latResults,berResults,snrResults,fsplResults,distance,timeSamples] = calculateLinkBudget(gsORsat,sat,cfg,modType,modOrder,modIndex,startTime,duration,sampleTime)

    % Pre-allocate results for FSPL and time
    endTime = startTime + seconds(duration); % Total simulation time (in sec)
    numSamples = floor(duration / sampleTime); % Number of samples taken
    snrResults = zeros(numSamples, 0);
    fsplResults = zeros(numSamples, 0);
    berResults = zeros(numSamples, 0);
    latResults = zeros(numSamples, 0);
    distance = zeros(numSamples,0);
    timeSamples = datetime.empty(numSamples, 0);
    timeSamples.TimeZone = startTime.TimeZone;

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
            maskAngle = 15;                   % Set mask angle to 15 degrees
            [az,el,vis] = lookangles(gsPos,satPosECEF,maskAngle);
    
            % Calculate the distance between the satellite and the ground station
            d = slantRangeCircularOrbit(el,satPos(3),gsPos(3)); % in meters
            cfg.Distance = d/1000;
    
            % Compute SNR and FSPL using the satelliteCNRConfig object
            [cn,info] = satelliteCNR(cfg);

            % Compute BER using EbNo from satelliteCNR function
            if strcmp(modType,'PSK')
                berResults(i) = berawgn(info.ReceivedEbNo,modType,modOrder,'nondiff');
            end
            if strcmp(modType,'FSK')
                berResults(i) = berawgn(info.ReceivedEbNo,modType,modOrder,'noncoherent');
            end
            if strcmp(modType,'QAM')
                berResults(i) = berawgn(info.ReceivedEbNo,modType,modOrder);
            end

            % Calculate the Latency Delay
            latResults(i) = latency(gsORsat,sat,currentTime);
            
            distance(i) = cfg.Distance;
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
            
            % Compute BER using EbNo from satelliteCNR function
            if strcmp(modType,'PSK')
                berResults(i) = berawgn(info.ReceivedEbNo,modType,modOrder,'nondiff');
            end
            if strcmp(modType,'FSK')
                berResults(i) = berawgn(info.ReceivedEbNo,modType,modOrder,'noncoherent');
            end
            if strcmp(modType,'QAM')
                berResults(i) = berawgn(info.ReceivedEbNo,modType,modOrder);
            end

            % Calculate the Latency Delay
            latResults(i) = latency(gsORsat,sat,currentTime);

            snrResults(i) = cn;             % Save SNR result
            distance(i) = cfg.Distance;
            fsplResults(i) = info.FSPL ;    % Save FSPL result
            timeSamples(i) = currentTime;   % Save current time
        
        end
    end
end

function [latResults,berResults,snrResults,fsplResults,distance,timeSamples] = calculateLinkBudget_multipleIntervals(gsORsat,sat,cfg,modType,modOrder,modIndex,sampleTime)
    ac = access(gsORsat,sat);               % Creates access analysis object
    intvls = accessIntervals(ac);           % Creates tables of access intervals
    numIntvls = height(intvls);


    for i = 1:numIntvls
        acStartTime = intvls(i,4).StartTime;
        acDuration = intvls(i,6).Duration;
        [lat{i},ber{i},snr{i},fspl{i},distance{i},time{i}] = calculateLinkBudget(gsORsat,sat,cfg,modType,modOrder,modIndex,acStartTime,acDuration,sampleTime);
    end

    latResults = [lat{:}];
    berResults = [ber{:}];
    snrResults = [snr{:}];
    fsplResults = [fspl{:}];
    distance = [distance{:}];
    timeSamples = [time{:}];
end

% Calculate Bit Rate
function bitRate = calculateBitRate(bandwidth,modType,modOrder,modIndex)

    % Check for modulation scheme
    if strcmp(modType,'qam') || strcmp(modType,'psk')
        bitRate = bandwidth * log2(modOrder);
    end
    if strcmp(modType,'fsk')
        bitRate = bandwidth / (2 * (1+modIndex));
    end
end
% 
% modType = 'psk';                                % modulation scheme
% modOrder = 16;                                   % modulation order
% modIndex = 1;                                   % modulation index

% % Create CNR Config object to for satelliteCNR function
% cfg = satelliteCNRConfig;
% cfg.TransmitterPower = 15;          % in dBW
% cfg.TransmitterSystemLoss = 3;      % in dB
% cfg.TransmitterAntennaGain = 25;     % in dBi
% cfg.Frequency = 2.4;                  % in GHz
% cfg.MiscellaneousLoss = 0;        % in dB
% cfg.GainToNoiseTemperatureRatio = cfg.TransmitterAntennaGain - 10*log10(290);   % in dB/K
% cfg.ReceiverSystemLoss = 3;         % in dB
% cfg.Bandwidth = 0.0315;                      % in MHz
% cfg.BitRate = calculateBitRate(cfg.Bandwidth,modType,modOrder,modIndex);                   % in Mbps
% 
% [latResults,berResults,snrResults,fsplResults,distance,timeSamples] = calculateLinkBudget_multipleIntervals(gs,sat(31),cfg,modType,modOrder,modIndex,sampleTime);
