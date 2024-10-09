function scenarioout = create_scenario(startdate, duration, steptime)
    time = hours(duration);
    scenarioout.scenario = satelliteScenario(startdate, startdate+time, steptime);
    scenarioout.viewer = satelliteScenarioViewer(scenarioout.scenario);
end