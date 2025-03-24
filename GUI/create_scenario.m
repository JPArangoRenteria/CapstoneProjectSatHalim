function scenarioout = create_scenario(startdate, duration, steptime)
    scenarioout.scenario = satelliteScenario(startdate, startdate+duration, steptime);
    scenarioout.viewer = satelliteScenarioViewer(scenarioout.scenario);
end