<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost", "root", "cs498", "bike_project");
if ($conn->connect_error) {
	http_response_code(500);
	echo json_encode(["error" => "Database connection failed"]);
	exit;
}

$result = $conn->query("SELECT bike_id, name, latitude, longitude, state, reportedIssue FROM yellow_bike_coordinates");
$bikes = [];
while ($row = $result->fetch_assoc()) {
	$bikes[] = $row;
}
echo json_encode($bikes);
$conn->close();
?>
