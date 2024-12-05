function streamlined = streamlinedaccess(scenario,accessobj,aircraft)
    % Vars needed
    connectedaccessrow = 1;
    connected = false;
    tablerow = 1;

    % Getting current and end time
    scenariostart = scenario.scenario.StartTime;
    scenariostart.Format = 'd-MMMM-yyyy HH:mm:ss';
    scenariostart.TimeZone = '';
    scenarioend = scenario.scenario.StopTime;
    scenarioend.Format = 'd-MMMM-yyyy HH:mm:ss';
    scenarioend.TimeZone = '';

    timevector = scenariostart:minutes(1):scenarioend;
    vectorsize = size(timevector, 2);

    streamlined = table('Size',[vectorsize 4], 'VariableTypes', {'string', 'datetime', 'datetime', 'double'}, 'VariableNames',{'Satellite', 'Connection Start', 'Connection End', 'FSPL'});

    % Start of Sim
    starttime = accessobj.Intervals.StartTime(connectedaccessrow);
    starttime.TimeZone = '';
    starttime.Format = 'd-MMMM-yyyy HH:mm:ss';
    streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), starttime, accessobj.Intervals.FSPL(connectedaccessrow)};
    connected = true;

    for vectorindex = 1:vectorsize % For each minute
        currenttime = timevector(vectorindex);
        currenttime.Format = 'd-MMMM-yyyy HH:mm:ss';
        currenttime.TimeZone = '';

        connectedsatend = accessobj.Intervals.EndTime(connectedaccessrow);
        connectedsatend.Format = 'd-MMMM-yyyy HH:mm:ss';
        connectedsatend.TimeZone = '';

        if currenttime == connectedsatend % If already connected sat ends
            connected = false;
            streamlined(tablerow, 3) = {currenttime};
        end

        if connected % If connected
            for rownumber = connectedaccessrow:size(accessobj.Intervals.Source,1)
                % Get sat connection times
                satstart = accessobj.Intervals.StartTime(rownumber);
                satstart.Format = 'd-MMMM-yyyy HH:mm:ss';
                satstart.TimeZone = '';
    
                satend = accessobj.Intervals.EndTime(rownumber);
                satend.Format = 'd-MMMM-yyyy HH:mm:ss';
                satend.TimeZone = '';
    
                intime = isbetween(currenttime, satstart, satend);
    
                if intime % If theres a sat within range at the time
                    if accessobj.Intervals.FSPL(rownumber) < accessobj.Intervals.FSPL(connectedaccessrow) % If better FSPL
                        % Disconnect from old
                        streamlined(tablerow, 3) = {currenttime};
                        
                        % Connect to new
                        tablerow = tablerow + 1;
                        connectedaccessrow = rownumber;
                        streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), currenttime, accessobj.Intervals.FSPL(connectedaccessrow)};
                    end
                end        
            end

            
        % If not connected
        elseif connected == false
            for nonconnectedindex = connectedaccessrow+1:size(accessobj.Intervals.Source,1)
                satstart = accessobj.Intervals.StartTime(nonconnectedindex);
                satstart.Format = 'd-MMMM-yyyy HH:mm:ss';
                satstart.TimeZone = '';
        
                satend = accessobj.Intervals.EndTime(nonconnectedindex);
                satend.Format = 'd-MMMM-yyyy HH:mm:ss';
                satend.TimeZone = '';
        
                intime = isbetween(currenttime, satstart, satend);
                reconnected = false;
        
                if intime % If there's a sat in range at the time
                    if reconnected == false % If we haven't already reconnected
                        tablerow = tablerow + 1;
                        connectedaccessrow = nonconnectedindex;
                        accessobj.Intervals.Source(connectedaccessrow);
                        streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), currenttime, accessobj.Intervals.FSPL(connectedaccessrow)};
                        connected = true;
                        reconnected = true;
                    
                    elseif reconnected == true % If we did reconnect, multiple sats in range
                        if accessobj.Intervals.FSPL(nonconnectedindex) < accessobj.Intervals.FSPL(connectedaccessrow) % If better FSPL
                        % Disconnect from old
                        streamlined(tablerow, 3) = {currenttime};
                        
                        % Connect to new
                        tablerow = tablerow + 1;
                        connectedaccessrow = nonconnectedindex;
                        streamlined(tablerow, [1, 2, 4]) = {accessobj.Intervals.Source(connectedaccessrow), currenttime, accessobj.Intervals.FSPL(connectedaccessrow)};
                        end
                    end
                end
            end
        end
    end
    % Cleaning up
    streamlined = rmmissing(streamlined);
end