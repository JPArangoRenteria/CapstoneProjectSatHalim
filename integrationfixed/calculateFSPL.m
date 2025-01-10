function [fsplResults, timeSamples, obj_type] = calculateFSPL(gsORsat, sat, startTime, endTime, sampleTime, lambda)
    % Pre-allocate results for FSPL and time
    duration = seconds(endTime - startTime); % Total simulation time (in sec)
    numSamples = floor(duration / sampleTime); % Number of samples taken
    fsplResults = zeros(numSamples, 1);
    timeSamples = datetime.empty(numSamples, 0);
    obj_type = zeros(numSamples, 1);

    % Ensure consistent time zone for startTime and endTime
    startTime.TimeZone = ''; % Remove time zone
    endTime.TimeZone = '';   % Remove time zone

    if isa(gsORsat, 'matlabshared.satellitescenario.GroundStation')
        disp('YES');
        for i = 1:numSamples
            currentTime = startTime + seconds((i-1) * sampleTime);
            if currentTime > endTime
                currentTime = endTime;
            end
            currentTime.TimeZone = ''; % Ensure no time zone

            [satPos, ~] = states(sat, currentTime, 'CoordinateFrame', 'geographic');
            [satECEF, ~] = states(sat, currentTime, 'CoordinateFrame', 'ecef');
            satPosECEF = [satECEF(1) satECEF(2) satECEF(3)];

            gsPos = [gsORsat.Latitude gsORsat.Longitude gsORsat.Altitude];
            maskAngle = 15; % Minimum elevation angle
            [az, el, vis] = lookangles(gsPos, satPosECEF, maskAngle);
            d = slantRangeCircularOrbit(el, satPos(3), gsPos(3));

            pathLoss = fspl(d, lambda);
            fsplResults(i) = pathLoss;
            timeSamples(i) = currentTime;
            obj_type(i) = 1;
        end
    else
        disp('NO');
        for i = 1:numSamples
            currentTime = startTime + seconds((i-1) * sampleTime);
            if currentTime > endTime
                currentTime = endTime;
            end
            currentTime.TimeZone = ''; % Ensure no time zone

            [sat1Pos, ~] = states(sat, currentTime, 'CoordinateFrame', 'geographic');
            [sat1ECEF, ~] = states(sat, currentTime, 'CoordinateFrame', 'ecef');
            sat1PosECEF = [sat1ECEF(1) sat1ECEF(2) sat1ECEF(3)];

            [sat2Pos, ~] = states(gsORsat, currentTime, 'CoordinateFrame', 'geographic');
            [sat2ECEF, ~] = states(gsORsat, currentTime, 'CoordinateFrame', 'ecef');
            sat2PosECEF = [sat2ECEF(1) sat2ECEF(2) sat2ECEF(3)];

            d1 = norm(sat1Pos - sat2Pos);

            pathLoss = fspl(d1, lambda);
            fsplResults(i) = pathLoss;
            timeSamples(i) = currentTime;
            obj_type(i) = 0;
        end
    end
end



