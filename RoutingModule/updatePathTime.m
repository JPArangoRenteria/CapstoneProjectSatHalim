function updatePathTime(scenario, pathtable, accessobj)
    % Ensure scenario doesn't auto-simulate
    scenario.AutoSimulate = false;

    % Initialize all access links as hidden and red
    %hide(accessobj.obj, satelliteScenarioViewer(scenario));
    %accessobj.obj.LineColor = 'green'; % Default color for all links
    %show(satelliteScenarioViewer(scenario));
    satelliteScenarioViewer(scenario);
    % Validate if pathtable is empty
    if isempty(pathtable)
        error("The path table is empty. Ensure routing data is correctly generated.");
    end

    % Initialize first path index
    index = 1;

    % Extract initial path and time details
    currentPath = pathtable.Path{index};
    startTime = pathtable.TimeInterval(index);

    % Remove time zones for consistency
    startTime.TimeZone = '';

    % Define simulation boundaries
    startSim = scenario.StartTime;
    endSim = scenario.StopTime;
    startSim.TimeZone = '';
    endSim.TimeZone = '';

    % Advance the simulation
    while advance(scenario)
        % Get the current simulation time
        currentTime = scenario.SimulationTime;
        currentTime.TimeZone = '';

        % If the current time matches the scheduled path change
        if isequal(currentTime, startTime) && ~isequal(currentTime, endSim)
            % Reset all links to red
            for i=1:length(accessobj)
                accessobj{i}.LineColor = 'green';
            end

            % Modify links for the shortest path
            updateAccessLinks(currentPath, accessobj, scenario);

            % Increment the path index
            index = index + 1;

            % If there are no more paths, exit
            if index > height(pathtable)
                disp("No more path updates. Ending simulation.");
                break;
            end

            % Get the next path and update start time
            currentPath = pathtable.Path{index};
            startTime = pathtable.TimeInterval(index);
            startTime.TimeZone = '';
        end
    end
end

%% **Function to Update Link Colors for the Shortest Path**
function updateAccessLinks(path, accessobj, scenario)
    disp('Updating shortest path links...');

    % Iterate through path nodes
    for i = 1:length(path)-1
        srcNode = extractNodeNumber(path{i});
        tgtNode = extractNodeNumber(path{i+1});

        % Locate the access link
        linkIndex = findAccessLink(accessobj, srcNode, tgtNode);

        % If link is found, update color
        if ~isempty(linkIndex)
            accessobj{linkIndex}.LineColor = 'red'; % Active path link
            disp(['Updated path link: ', num2str(srcNode), ' -> ', num2str(tgtNode)]);
        else
            disp(['No access link found for: ', num2str(srcNode), ' -> ', num2str(tgtNode)]);
        end
    end

    % Force graphical update
    drawnow;
end

%% **Function to Extract Numeric Node Identifier**
function nodeNum = extractNodeNumber(nodeStr)
    numMatch = regexp(nodeStr, '\d+', 'match');
    nodeNum = str2double(numMatch{1});
end

%% **Function to Find Access Link in the Scenario**
function linkIndex = findAccessLink(accessobj, srcNode, tgtNode)
    linkIndex = [];
    
    for j = 1:length(accessobj)
        seq = accessobj{j}.Sequence;
        if (seq(1) == srcNode && seq(2) == tgtNode) || (seq(1) == tgtNode && seq(2) == srcNode)
            linkIndex = j;
            return; % Stop once the link is found
        end
    end
end

