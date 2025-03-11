from opensky_api import OpenSkyApi
import pandas as pd
import time

api = OpenSkyApi()

#  Gather flights that arrive in "CYOW" and depart "CYVR" from March 3-10
arrivals = api.get_arrivals_by_airport("CYOW",1740978000,1741579200)
counter = 1
for flight in arrivals:
    if flight.estDepartureAirport == "CYVR":
        print(flight.icao24, flight.firstSeen)

        # Tracks single aircraft, from the starting the time in UNIX time
        track = api.get_track_by_aircraft(flight.icao24,flight.firstSeen)

        flight_path = []

        # For each time stamp, divide data into variables and convert date & time
        for entry in track.path:
            timestamp, lat, lon, altitude, velocity, heading = entry
            readable_time = time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime(timestamp))

            # Add data to csv formatted variable
            flight_path.append({
                "Timestamp": readable_time,
                "Latitude": lat,
                "Longitude": lon
            })

        # Output data to a CSV file
        df = pd.DataFrame(flight_path, columns=["Timestamp","Latitude","Longitude"])
        csv_filename = "Van_to_Ott%i.csv"%(counter)
        df.to_csv(csv_filename, index=False)

        counter += 1
        
