<?php
$to = 'siripapornpansurin7@gmail.com';
$subject = 'Test Mail';
$message = 'Hello from PHP mail()';
$headers = 'From: 661463033@crru.ac.th' . "\r\n" .
    'Reply-To: 661463033@crru.ac.th' . "\r\n" .
    'X-Mailer: PHP/' . phpversion();

if (mail($to, $subject, $message, $headers)) {
    echo "Mail sent successfully!";
} else {
    echo "Mail sending failed.";
}
