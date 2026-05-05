<?php
// 1. Connection Details (Localhost works because the script is ON the server)
$host = "localhost";
$user = "pmgorman";
$pass = "1340613";
$db   = "bike_project";

$conn = mysqli_connect($host, $user, $pass, $db);

if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

// 2. Get data from the App's "POST" request
$bike_id = $_POST['bike_id'];
$lat     = $_POST['latitude'];
$lon     = $_POST['longitude'];

// 3. Insert into your table
$sql = "INSERT INTO yellow_bike_coordinates (bike_id, latitude, longitude) 
        VALUES ('$bike_id', '$lat', '$lon')";

if (mysqli_query($conn, $sql)) {
    echo "Success";
} else {
    echo "Error: " . mysqli_error($conn);
}

mysqli_close($conn);
?>
