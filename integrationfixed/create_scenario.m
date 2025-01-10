function scenarioout = create_scenario(sc)
    %time = hours(duration);
    scenarioout.scenario = sc;%satelliteScenario(startdate, startdate+time, steptime);
    scenarioout.viewer = satelliteScenarioViewer(scenarioout.scenario);
 
end
