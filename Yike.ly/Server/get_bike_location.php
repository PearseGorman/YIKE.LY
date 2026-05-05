$sql = "SELECT bike_id as id, name, state, latitude, longitude, reportedIssue, timestamp FROM yellow_bike_coordinates WHERE bike_id = '$bike_id' ORDER BY timestamp DESC LIMIT 1";$sql = "SELECT bike_id as id, name, state, latitude, longitude, reportedIssue, timestamp FROM yellow_bike_coordinates WHERE bike_id = '$bike_id' ORDER BY timestamp DESC LIMIT 1";<?php
$host = "localhost";
$user = "pmgorman";
$pass = "1340613";
$db   = "bike_project";

$conn = mysqli_connect($host, $user, $pass, $db);

// Get the bike_id from the Swift app's request
$bike_id = $_GET['bike_id'];

// Query for the MOST RECENT coordinate for that specific bike
$sql = "SELECT latitude, longitude, timestamp 
        FROM yellow_bike_coordinates 
        WHERE bike_id = '$bike_id' 
        ORDER BY timestamp DESC LIMIT 1";

$result = mysqli_query($conn, $sql);

if ($row = mysqli_fetch_assoc($result)) {
    // This turns the database row into a format Swift loves (JSON)
    echo json_encode($row);
} else {
    echo json_encode(["error" => "Bike not found"]);
}

mysqli_close($conn);
?>
