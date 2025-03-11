from opensky_api import OpenSkyApi
import pandas as pd
import time

api = OpenSkyApi()
# arrivals = api.get_arrivals_by_airport("CYOW",1740978000,1741579200)
# for flight in arrivals:
    # if flight.estDepartureAirport == "CYVR":
        # print(flight.icao24)
        # track = api.get_track_by_aircraft(flight.icao24)
        # print(track)

track = api.get_track_by_aircraft("c030fd",1740979863)

flight_path = []

for entry in track.path:
    timestamp, lat, lon, altitude, velocity, heading = entry
    readable_time = time.strftime('%Y-%m-%d %H:%M:%S',time.gmtime(timestamp))

    flight_path.append({
        "Timestamp": readable_time,
        "Latitude": lat,
        "Longitude": lon
    })

df = pd.DataFrame(flight_path, columns=["Timestamp","Latitude","Longitude"])
csv_filename = "flight_c030fd_track.csv"
df.to_csv(csv_filename, index=False)